module Lunar
  # @private Used internally by Lunar::search to get all the range matches
  # given `nest`, `att` and it's `val`.
  class RangeMatches
    MAX_RESULTS = 10_000

    attr :nest
    attr :att
    attr :range

    def initialize(nest, att, range)
      @nest, @att, @range = nest, att.to_sym, range
    end


    def distkey
      nest[{ att => range }.hash].tap do |dk|
        res = zset.zrangebyscore(range.first, range.last, :limit => [0, MAX_RESULTS])
        res.each { |val| dk.zadd(1, val) }
      end
    end

  private
    def zset
      @sortedset ||= nest[:Numbers][att]
    end
  end
end