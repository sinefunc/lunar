require 'base64'
require 'redis'
require 'nest'
require 'text'

module Lunar
  VERSION = '0.5.6'

  autoload :Connection,     "lunar/connection"
  autoload :LunarNest,      "lunar/lunar_nest"
  autoload :Index,          "lunar/index"
  autoload :Scoring,        "lunar/scoring"
  autoload :Words,          "lunar/words"
  autoload :Stopwords,      "lunar/stopwords"
  autoload :FuzzyWord,      "lunar/fuzzy_word"
  autoload :NumberMatches,  "lunar/number_matches"
  autoload :KeywordMatches, "lunar/keyword_matches"
  autoload :RangeMatches,   "lunar/range_matches"
  autoload :FuzzyMatches,   "lunar/fuzzy_matches"
  autoload :ResultSet,      "lunar/result_set"

  extend Connection

  # Index any document using a namespace. The namespace can
  # be a class, or a plain Symbol/String.
  #
  # @example
  #
  #   Lunar.index Gadget do |i|
  #     i.text  :name, 'iphone 3gs'
  #     i.text  :tags, 'mobile apple smartphone'
  #
  #     i.number :price, 200
  #     i.number :rating, 25.5
  #
  #     i.sortable :votes, 50
  #   end
  #
  # @see Lunar::Index#initialize
  # @param [String, Symbol, Class] namespace the namespace of this document.
  # @yield [Lunar::Index] an instance of Lunar::Index.
  # @return [Lunar::Index] returns the yielded Lunar::Index.
  def self.index(namespace)
    Index.new(namespace).tap { |i| yield i }
  end

  # Delete a document identified by its namespace and id.
  #
  # @param [#to_s] namespace the namespace of the document to delete.
  # @param [#to_s] id the id of the document to delete.
  # @return [nil]
  def self.delete(namespace, id)
    Index.new(namespace).delete(id)
  end

  # Search for a document, scoped under a namespace.
  #
  # @example
  #
  #   Lunar.search Gadget, :q => "apple"
  #   # returns all gadgets with `text` apple.
  #
  #   Lunar.search Gadget, :q => "apple", :description => "cool"
  #   # returns all gadgets with `text` apple and description:cool
  #
  #   Lunar.search Gadget, :q => "phone", :price => 200..250
  #   # returns all gadgets with `text` phone priced between 200 to 250
  #
  #   Lunar.search Customer, :fuzzy => { :name => "ad" }
  #   # returns all customers with their first / last name beginning with 'ad'
  #
  #   Lunar.search Customer, :fuzzy => { :name => "ad" }, :age => 20..25
  #   # returns all customers with name starting with 'ad' aged 20 to 25.
  #
  # @param [#to_s] namespace search under which scope e.g. Gadget
  # @param [Hash] options i.e. :q, :field1, :field2, :fuzzy
  # @option options [Symbol] :q keywords e.g. `apple iphone 3g`
  # @option options [Symbol] :field1 any field you indexed and a value
  # @option options [Symbol] :fuzzy hash of :key => :value pairs
  # @param [#to_proc] finder (optional) for cases where `Gadget[1]` isn't the
  #   method of finding. You can for example use an ActiveRecord model and
  #   pass in lambda { |id| Gadget.find(id) }.
  #
  # @return Lunar::ResultSet an Enumerable object.
  def self.search(namespace, options, finder = lambda { |id| namespace[id] })
    sets = find_and_combine_sorted_sets_for(namespace, options)
    key  = try_intersection_of_sorted_sets(namespace, sets, options)

    ResultSet.new(key, nest[namespace], finder)
  end

  # @private internally used for determining the metaphone of a word.
  def self.metaphone(word)
    Text::Metaphone.metaphone(word)
  end

  # @private abstraction of how encoding should be done for Lunar.
  def self.encode(word)
    Base64.encode64(word).strip
  end

  # @private convenience method for getting a scoped Nest.
  def self.nest
    LunarNest.new(:Lunar, redis)
  end

private
  def self.find_and_combine_sorted_sets_for(namespace, options)
    options.inject([]) do |sets, (key, value)|
      if value.is_a?(Range)
        sets << RangeMatches.new(nest[namespace], key, value).distkey
      elsif key == :fuzzy
        fuzzy_matches = value.map { |fuzzy_key, fuzzy_value|
          unless fuzzy_value.to_s.empty?
            FuzzyMatches.new(nest[namespace], fuzzy_key, fuzzy_value).distkey
          end
        }
        sets.push(*fuzzy_matches.compact)
      elsif key == :numbers
        number_matches = value.map { |num_key, num_value|
          unless num_value.to_s.empty?
            matches = NumberMatches.new(nest[namespace], num_key, num_value)
            sets << matches.distkey  if matches.distkey
          end
        }
      else
        unless value.to_s.empty?
          sets << KeywordMatches.new(nest[namespace], key, value).distkey
        end
      end

      sets
    end
  end

  def self.try_intersection_of_sorted_sets(namespace, sets, options)
    return if sets.empty?

    if sets.size == 1
      sets.first
    else
      nest[namespace][options.hash].zinterstore sets
      nest[namespace][options.hash]
    end
  end
end
