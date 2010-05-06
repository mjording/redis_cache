require 'redis'
require 'activesupport'
module ActiveSupport
  module Cache
    # A cache store implementation which stores data in Redis:
    #
    # This is currently the most popular cache store for production websites.
    #
    # Special features:
    # - Clustering and load balancing. One can specify multiple redis servers,
    #   and RedisStore will load balance between all available servers. If a
    #   server goes down, then RedisStore will ignore it until it goes back
    #   online.
    # - Time-based expiry support. See #write and the +:expires_in+ option.
    # - Per-request in memory cache for all communication with the Redis server(s).
    class RedisCache < Store

      def self.build_redis_cache(*addresses)
        addresses = addresses.flatten
        options = addresses.extract_options!
        addresses = ["localhost"] if addresses.empty?
        
        #Redis.connect(address, options)
      end

      # Creates a new RedisCache object, with the given redis server
      # addresses. Each address is either a host name, or a host-with-port string
      # in the form of "redis://host_name:port". For example:
      #
      #   ActiveSupport::Cache::RedisCache.new("localhost", "server-downstairs.localnetwork:8229")
      #
      # If no addresses are specified, then MemCacheStore will connect to
      # localhost port 11211 (the default memcached port).
      #
      # Instead of addresses one can pass in a MemCache-like object. For example:
      #
      #   require 'redis' # gem install redis; 
      #   ActiveSupport::Cache::RedisCache.new(Redis.connect(:url => "redis://localhost:6380/1"))
      def initialize(*addresses)
        if addresses.empty?
          @data = Redis.connect
        elsif addresses.size == 1
          @data = Redis.connect :url => "redis://#{addresses.first}"
        else
          @data = self.class.build_redis_cache(*addresses)
        end

        extend Strategy::LocalCache
      end

      # Reads multiple keys from the cache.
      def read_multi(*keys)
        @data.mget(*keys).map{|a| Marshal.load(a)  }
      end

      def read(key, options = nil) # :nodoc:
        super
        result = @data.get(key)
        result = Marshal.load result if unmarshal?(result, options)
      end

      # Writes a value to the cache.
      #
      # Possible options:
      # - +:unless_exist+ - set to true if you don't want to update the cache
      #   if the key is already set.
      # - +:expires_in+ - the number of seconds that this value may stay in
      #   the cache. See ActiveSupport::Cache::Store#write for an example.
      def write(key, value, options = nil)
        super
        val = raw?(options) ? value : Marshal.dump(value)
        @data.set(key, val)
      end

      def delete(key, options = nil) # :nodoc:
        super
        response = @data.del(key)
      end

      def exist?(key, options = nil) # :nodoc:
        @data.exists(key)
      end

      def increment(key, amount = 1) # :nodoc:
        log("incrementing", key, amount)
        @data.incr(key, amount)
      end

      def decrement(key, amount = 1) # :nodoc:
        log("decrement", key, amount)
        @data.decr(key, amount)
      end

      def delete_matched(matcher, options = nil) # :nodoc:
        super
        t = @data.keys(matcher)
        @data.del(*t)
        @data.keys(matcher).empty?
      end

      def clear
        @data.flush_all
      end

      def stats
        @data.stats
      end
      private
        def unmarshal?(result, options)
          result && result.size > 0 && !raw?(options)
        end

        def raw?(options)
          options && options[:raw]
        end

        def expires_in(options)
          if options
            # Rack::Session           Merb                    Rails/Sinatra
            options[:expire_after] || options[:expires_in] || options[:expire_in]
          end
        end
    end
  end
end
