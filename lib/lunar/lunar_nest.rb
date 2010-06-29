module Lunar
  # @private Provides convenience methods to look up keys.
  # Since the Redis KEYS command is actually pretty slow,
  # i'm considering an alternative approach of manually maintaining
  # the sets to manage all the groups of keys.
  class LunarNest < Nest
    def keys
      redis.keys self
    end

    def matches
      regex = Regexp.new(self.gsub('*', '(.*)'))
      keys.map { |key|
        match = key.match(regex)
        [LunarNest.new(key, redis), *match[1, match.size - 1]]
      }
    end
  end
end
