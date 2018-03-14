require "socrates/core/state_data"

module Socrates
  module Storage
    module Storage
      def initialize
        @error_logger = Socrates.config.error_logger
      end

      def fetch(client_id)
        key = generate_key(client_id)

        snapshot = get(key)

        return if snapshot.nil?

        begin
          Socrates::Core::StateData.deserialize(snapshot)
        rescue StandardError => e
          @error_logger.error "Error while fetching state_data for client id '#{client_id}', /
            resetting state: #{e.message}"
          @error_logger.error e
        end
      end

      def persist(client_id, state_data)
        key = generate_key(client_id)
        state_data.reset_elapsed_time
        put(key, state_data.serialize)
      end

      def generate_key(client_id)
        client_id
      end

      # rubocop:disable Lint/UnusedMethodArgument

      def has_key?(key)
        raise NotImplementedError
      end

      def clear(key)
        raise NotImplementedError
      end

      def get(key)
        raise NotImplementedError
      end

      def put(key, value)
        raise NotImplementedError
      end

      def clear_all
        raise NotImplementedError
      end

      # rubocop:enable Lint/UnusedMethodArgument
    end
  end
end
