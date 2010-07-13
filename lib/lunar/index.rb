module Lunar
  # Handles the management of indices for a given namespace.
  # Although you may use this directly, it's much more convenient
  # to use `Lunar::index` and `Lunar::delete`.
  #
  # @see Lunar::index
  # @see Lunar::delete
  class Index
    # This constant is in place to maintain a certain level of performance.
    # Fuzzy searching internally stores an index per letter i.e. for Quentin
    # q
    # qu
    # que
    # quen
    # quent
    # quenti
    # quentin
    # 
    # This can become pretty unweildy very fast, so we limit the length
    # of all fuzzy fields.
    FUZZY_MAX_LENGTH = 100
 
    # The following are all used to construct redis keys
    TEXT       = :Text
    METAPHONES = :Metaphones
    NUMBERS    = :Numbers
    SORTABLES  = :Sortables
    FUZZIES    = :Fuzzies
    FIELDS     = :Fields

    MissingID = Class.new(StandardError)
    FuzzyFieldTooLong = Class.new(StandardError)

    attr :nest
    attr :metaphones
    attr :numbers
    attr :sortables
    attr :fuzzies
    attr :fields

    # This is actually wrapped by `Lunar.index` and is not inteded to be
    # used directly.
    # @see Lunar::index
    # @param [#to_s] the namespace of the document you want to index.
    # @return [Lunar::Index]
    def initialize(namespace)
      @nest       = Lunar.nest[namespace]
      @metaphones = @nest[METAPHONES]
      @numbers    = @nest[NUMBERS]
      @sortables  = @nest[SORTABLES]
      @fuzzies    = @nest[FUZZIES]
      @fields     = @nest[FIELDS]
    end

    # Get / Set the id of the document
    # @example
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
      if value.respond_to?(:to_a)
        text(att, value.to_a.join(' ')) and return
      end

      clear_text_field(att)

      Scoring.new(value).scores.each do |word, score|
        metaphone = Lunar.metaphone(word)

        nest[att][metaphone].zadd(score, id)
        metaphones[id][att].sadd(metaphone)
      end

      fields[TEXT].sadd(att)
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
    def number(att, value, purge = true)
      if value.kind_of?(Enumerable)
        clear_number_field(att)

        value.each { |v| number(att, v, false) } and return
      end
      
      clear_number_field(att)  if purge

      numbers[att].zadd(value, id)
      numbers[att][value].zadd(1, id)
      numbers[id][att].sadd(value)

      fields[NUMBERS].sadd att
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

      fields[SORTABLES].sadd att
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
      assert_valid_fuzzy(value, att)

      clear_fuzzy_field(att)

      words = Words.new(value, [:downcase, :uniq])

      fuzzy_words_and_parts(words) do |word, parts|
        parts.each { |part, encoded| fuzzies[att][encoded].zadd(1, id) }
        fuzzies[id][att].sadd word
      end

      fields[FUZZIES].sadd att
    end

  private
    def assert_valid_fuzzy(value, att)
      if value.to_s.length > FUZZY_MAX_LENGTH
        raise FuzzyFieldTooLong,
          "#{att} has a value #{value} exceeding the max #{FUZZY_MAX_LENGTH}"
      end
    end

    def delete_metaphones
      fields[TEXT].smembers.each do |att|
        clear_text_field(att)
      end
    end

    def clear_text_field(att)
      metaphones[id][att].smembers.each do |metaphone|
        nest[att][metaphone].zrem id
      end

      metaphones[id][att].del
    end

    def delete_numbers
      fields[NUMBERS].smembers.each do |att|
        clear_number_field(att)
      end
    end

    def clear_number_field(att)
      numbers[id][att].smembers.each do |number|
        numbers[att][number].zrem(id)
        numbers[att].zrem(id)
      end

      numbers[id][att].del
    end


    def delete_sortables
      fields[SORTABLES].smembers.each { |att| sortables[id][att].del }
    end

    def delete_fuzzies
      fields[FUZZIES].smembers.each do |att|
        clear_fuzzy_field(att)
      end
    end
  
    def clear_fuzzy_field(att)
      fuzzy_words_and_parts(fuzzies[id][att].smembers) do |word, parts|
        parts.each do |part, encoded|
          fuzzies[att][encoded].zrem(id)
        end

        fuzzies[id][att].del
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
