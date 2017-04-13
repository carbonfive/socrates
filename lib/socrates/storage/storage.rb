require 'redis'
require 'json'

module Socrates
  module Storage
    class MemoryStorage
      def initialize
        @storage = {}
      end

      def has_key?(key)
        @storage.has_key? key
      end

      def clear(key)
        @storage.delete key
      end

      def get(key)
        @storage[key]
      end

      def put(key, value)
        @storage[key] = value
      end
    end

    class RedisStorage
      def initialize(url: 'redis://localhost')
        @redis = Redis.new(url: url)
      end

      def has_key?(key)
        @redis.exists(key)
      end

      def clear(key)
        @redis.del key
      end

      def get(key)
        @redis.get(key)
      end

      def put(key, value)
        @redis.set(key, value)
      end
    end
  end
end
