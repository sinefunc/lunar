module Lunar
  # @private Used internally by Lunar::search to get all the fuzzy matches
  # given `nest`, `att` and it's `val`.
  class FuzzyMatches
    attr :nest
    attr :att
    attr :value

    def initialize(nest, att, value)
      @nest, @att, @value = nest, att.to_sym, value
    end

    def distkey
      nest[{ att => value }.hash].tap do |dk|
        dk.zunionstore keys.flatten
      end
    end

  protected
    def keys
      Words.new(value).map { |w| nest[:Fuzzies][att][Lunar.encode(w)] }
    end
  end
end