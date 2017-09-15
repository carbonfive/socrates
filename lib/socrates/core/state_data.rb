require "hashie"
require "json"
require "yaml"
require "active_support/core_ext/numeric/time"
require "socrates/configuration"

module Socrates
  module Core
    class StateData
      END_OF_CONVERSATION = :__end__

      attr_accessor :state_id, :state_action, :last_interaction_timestamp

      def initialize(state_id: nil, state_action: nil, data: {})
        @state_id       = state_id
        @state_action   = state_action
        @data           = data
        @temporary_keys = []
      end

      def finished?
        @state_id.nil? || @state_id == END_OF_CONVERSATION
      end

      def expired?
        return false if last_interaction_timestamp.nil? ||
                        Socrates.config.expired_timeout.nil? ||
                        Socrates.config.expired_timeout.zero?

        elapsed_time > Socrates.config.expired_timeout
      end

      def elapsed_time
        Time.current - @last_interaction_timestamp
      end

      def reset_elapsed_time
        @last_interaction_timestamp = Time.current
      end

      def each_key(&block)
        @data.each_key(&block)
      end

      def keys
        @data.keys
      end

      def has_key?(key)
        @data.has_key?(key)
      end

      def has_temporary_key?(key)
        @temporary_keys.include?(key)
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
