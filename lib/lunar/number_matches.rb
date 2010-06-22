module Lunar
  # @private Used internally by Lunar::search to get all the fuzzy matches
  # given `nest`, `att` and it's `val`.
  class NumberMatches
    attr :nest
    attr :att
    attr :value

    def initialize(nest, att, value)
      @nest, @att, @value = nest, att.to_sym, value.to_s
    end

    def distkey
      nest[:Numbers][att][value]
      # return if keys.empty?

      # nest[{ att => value }.hash].tap do |dk|
      #   dk.zunionstore keys.flatten
      # end
    end

  protected
    # def keys
    #   Words.new(value, false).map { |w| nest[:Numbers][att][w] }
    # end
  end
end
