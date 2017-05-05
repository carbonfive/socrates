require "redis"

module Socrates
  module Storage
    class Redis
      def initialize(url: "redis://localhost")
        @redis = Redis.new(url: url)
      end

      def has_key?(key)
        @redis.exists(key)
      end

      def clear(key)
        @redis.del(key)
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
