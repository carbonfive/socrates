module Socrates
  module Storage
    class Memory
      def initialize
        @memory = {}
      end

      def has_key?(key)
        @memory.has_key?(key)
      end

      def clear(key)
        @memory.delete(key)
      end

      def get(key)
        @memory[key]
      end

      def put(key, value)
        @memory[key] = value
      end
    end
  end
end
