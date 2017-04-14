require "hashie"
require "json"
require "set"
require "yaml"

module Socrates
  module Core
    class StateData
      attr_accessor :state_id, :state_action

      def initialize(state_id: nil, state_action: nil, data: {}, temporary_keys: [])
        @state_id       = state_id
        @state_action   = state_action
        @data           = data
        @temporary_keys = Set.new(temporary_keys)
      end

      def keys
        @data.keys
      end

      def has_key?(key)
        @data.has_key?(key)
      end

      def has_temporary_key?(key)
        # The !! turns nils into false, which shouldn"t be necessary, but seems to be after the set is loaded from yaml.
        @temporary_keys.include?(key) == true
      end

      def get(key, clear: false)
        value = @data[key]

        if @temporary_keys.include?(key) || clear
          @temporary_keys.delete(key)
          @data.delete(key)
        end

        value
      end

      def set(key, value)
        @data[key] = value
      end

      def set_temporary(key, value)
        if @data.has_key?(key) && !@temporary_keys.include?(key)
          raise ArgumentError, "Cannot overrite key '#{key}' with a temporary value."
        end

        @data[key] = value
        @temporary_keys << key
      end

      def merge(other)
        @data.merge!(other)
      end

      def clear(key = nil)
        if key
          @data.delete(key)
          @temporary_keys.delete(key)
        else
          @data.clear
          @temporary_keys.clear
        end
      end

      def serialize
        YAML.dump(self)
      end

      def self.deserialize(string)
        YAML.load(string)
      end
    end
  end
end
