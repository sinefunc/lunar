module Lunar
  # Handles the management of indices for a given namespace.
  # Although you may use this directly, it's much more convenient
  # to use `Lunar::index` and `Lunar::delete`.
  #
  # @see Lunar::index
  # @see Lunar::delete
  class Index
    FUZZY_MAX_LENGTH = 100

    MissingID = Class.new(StandardError)
    FuzzyFieldTooLong = Class.new(StandardError)

    attr :nest
    attr :metaphones
    attr :numbers
    attr :sortables
    attr :fuzzies

    # This is actually wrapped by `Lunar.index` and is not inteded to be
    # used directly.
    # @see Lunar::index
    # @param [#to_s] the namespace of the document you want to index.
    # @return [Lunar::Index]
    def initialize(namespace)
      @nest       = Lunar.nest[namespace]
      @metaphones = @nest[:Metaphones]
      @numbers    = @nest[:Numbers]
      @sortables  = @nest[:Sortables]
      @fuzzies    = @nest[:Fuzzies]
    end

    # Get / Set the id of the document
    # @example:
    #
    #   # Wrong usage:
    #   Lunar.index :Gadget do |i|
    #     i.text :name, 'iPad'
    #   end
    #   # => raise MissingID
    #
    #   # Correct usage:
    #   Lunar.index :Gadget do |i|
    #     i.id 1001 # this appears before anything.
    #     i.text :name, 'iPad' # ok now you can set other fields.
    #   end
    #
    # The `id` is used for all other keys to define the structure of the
    # keys, therefore it's imperative that you set it first.
    #
    # @param [#to_s] the id of the document you want to index.
    # @raise [Lunar::Index::MissingID] when you access without setting it first
    # @return [String] the `id` you set.
    def id(value = nil)
      @id = value.to_s if value
      @id or raise MissingID, "In order to index a document, you need an `id`"
    end

    # Indexes all the metaphone equivalents of the words
    # in value except for words included in Stopwords.
    #
    # @example
    #
    #   Lunar.index :Gadget do |i|
    #     i.id 1001
    #     i.text :title, "apple macbook pro"
    #   end
    #
    #   # Executes the ff: in redis:
    #   #
    #   # ZADD Lunar:Gadget:title:APL  1 1001
    #   # ZADD Lunar:Gadget:title:MKBK 1 1001
    #   # ZADD Lunar:Gadget:title:PR   1 1001
    #   #
    #   # In addition a reference of all the words are stored
    #   # SMEMBERS Lunar:Gadget:Metaphones:1001:title
    #   # => (APL, MKBK, PR)
    #
    # @param [Symbol] att the field name in your document
    # @param [String] value the content of the field name
    #
    # @return [Array<String>] all the metaphones added for the document.
    def text(att, value)
      old = metaphones[id][att].smembers
      new = []

      Scoring.new(value).scores.each do |word, score|
        metaphone = Lunar.metaphone(word)

        nest[att][metaphone].zadd(score, id)
        metaphones[id][att].sadd(metaphone)
        new << metaphone
      end

      (old - new).each do |metaphone|
        nest[att][metaphone].zrem(id)
        metaphones[id][att].srem(metaphone)
      end

      return new
    end

    # Adds a numeric index for `att` with `value`.
    #
    # @example
    #
    #   Lunar.index :Gadget do |i|
    #     i.id 1001
    #     i.number :price, 200
    #   end
    #
    #   # Executes the ff: in redis:
    #   #
    #   # ZADD Lunar:Gadget:price 200
    #
    # @param [Symbol] att the field name in your document.
    # @param [Numeric] value the numeric value of `att`.
    #
    # @return [Boolean] whether or not the value was added
    def number(att, value)
      numbers[att].zadd(value, id)
    end

    # Adds a sortable index for `att` with `value`.
    #
    # @example
    #
    #   class Gadget
    #     def self.[](id)
    #       # find the gadget using id here
    #     end
    #   end
    #
    #   Lunar.index Gadget do |i|
    #     i.id 1001
    #     i.text 'apple macbook pro'
    #     i.sortable :votes, 50
    #   end
    #
    #   Lunar.index Gadget do |i|
    #     i.id 1002
    #     i.text 'apple iphone 3g'
    #     i.sortable :votes, 20
    #   end
    #
    #   results = Lunar.search(Gadget, :q => 'apple')
    #   results.sort(:by => :votes, :order => 'DESC')
    #   # returns [Gadget[1001], Gadget[1002]]
    #
    #   results.sort(:by => :votes, :order => 'ASC')
    #   # returns [Gadget[1002], Gadget[1001]]
    #
    # @param [Symbol] att the field you want to have sortability.
    # @param [String, Numeric] value the value of the sortable field.
    #
    # @return [String] the response from the redis server.
    def sortable(att, value)
      sortables[id][att].set(value)
    end

    # Deletes everything related to an existing document given its `id`.
    #
    # @param [#to_s] id the document's id.
    # @return [nil]
    def delete(existing_id)
      id(existing_id)
      delete_metaphones
      delete_numbers
      delete_sortables
      delete_fuzzies
    end

    def fuzzy(att, value)
      if value.to_s.length > FUZZY_MAX_LENGTH
        raise FuzzyFieldTooLong,
          "#{att} has a value #{value} exceeding the max #{FUZZY_MAX_LENGTH}"
      end

      words = Words.new(value).uniq

      fuzzy_words_and_parts(words) do |word, parts|
        parts.each do |part, encoded|
          fuzzies[att][encoded].zadd(1, id)
        end
        fuzzies[id][att].sadd word
      end

      delete_fuzzies_for(att, fuzzies[id][att].smembers - words, words)
    end

  private
    def delete_metaphones
      metaphones[id]['*'].matches.each do |key, att|
        key.smembers.each do |metaphone|
          nest[att][metaphone].zrem id
        end

        key.del
      end
    end

    def delete_numbers
      numbers['*'].matches.each do |key, att|
        numbers[att].zrem(id)
      end
    end

    def delete_sortables
      sortables[id]['*'].keys.each do |key|
        Lunar.redis.del key
      end
    end

    def delete_fuzzies
      fuzzies[id]['*'].matches.each do |key, att|
        delete_fuzzies_for(att, key.smembers)
        key.del
      end
    end

    def delete_fuzzies_for(att, words_to_delete, existing_words = [])
      fuzzy_words_and_parts(words_to_delete) do |word, parts|
        parts.each do |part, encoded|
          next if existing_words.grep(/^#{part}/u).any?
          fuzzies[att][encoded].zrem(id)
        end
        fuzzies[id][att].srem word
      end
    end

    def fuzzy_words_and_parts(words)
      words.each do |word|
        partials =
          FuzzyWord.new(word).partials.map do |partial|
            [partial, Lunar.encode(partial)]
          end

        yield word, partials
      end
    end
  end
end