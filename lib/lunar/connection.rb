module Lunar
  # This is actually taken from Ohm (http://ohm.keyvalue.org). The Lunar module 
  # extends this to make the API easier to use.
  #
  #   Lunar.connect(:host => "127.0.0.1", :port => "6380")
  #   Lunar.redis
  #   # basically returns Redis.new(:host => "127.0.0.1", :port => "6380")
  #
  #   # If you don't provide any connection, it assumes you are referring
  #   # to the default redis host / port (127.0.0.1 on port 6379)
  #   Lunar.redis
  #
  module Connection
    # Connect to a redis database.
    #
    # @param options [Hash] options to create a message with.
    # @option options [#to_s] :host ('127.0.0.1') Host of the redis database.
    # @option options [#to_s] :port (6379) Port number.
    # @option options [#to_s] :db (0) Database number.
    # @option options [#to_s] :timeout (0) Database timeout in seconds.
    # @example Connect to a database in port 6380.
    #   Lunar.connect(:port => 6380)
    def connect(*options)
      self.redis = nil
      @options = options
    end

    # @private Provides access to the Redis database. This is shared accross all
    # models and instances.
    #
    # @return [Redis] an instance of Redis
    def redis
      threaded[:redis] ||= connection(*options)
    end

    # @private Set the Redis database connection
    # @param [Redis] connection the redis connection
    def redis=(connection)
      threaded[:redis] = connection
    end

  private
    # @private internally used for connection thread saftey
    def threaded
      Thread.current[:lunar] ||= {}
    end

    # @private Return a connection to Redis.
    #
    # This is a wapper around Redis.new(options)
    def connection(*options)
      Redis.new(*options)
    end

    # @private Return a connection to Redis.
    #
    # stores the connection options. used by Lunar::Connection::connect
    def options
      @options || []
    end
  end
end
