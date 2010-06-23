module Lunar
  # @private Used internally by Lunar::search to get all the fuzzy matches
  # given `nest`, `att` and it's `val`.
  class NumberMatches
    attr :nest
    attr :att
    attr :values

    def initialize(nest, att, value)
      @nest   = nest
      @att    = att
      @values = value.kind_of?(Enumerable) ? value : [value]
    end

    def distkey
      case keys.size
      when 0 then nil
      when 1 then keys.first
      else
        nest[{ att => values }.hash].tap do |dk|
          dk.zunionstore keys.flatten
        end
      end
    end

  protected
    def keys
      values.
        reject { |v| v.to_s.empty? }.
        map    { |v| nest[:Numbers][att][v] }
    end
  end
end
