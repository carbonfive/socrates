require "hashie"
require "active_support/all"

require "socrates/configuration"
require "socrates/logger"
require "socrates/string_helpers"
require "socrates/storage/memory"
require "socrates/core/state"
require "socrates/core/state_data"

module Socrates
  module Core
    class Dispatcher
      def initialize(adapter:, state_factory:, storage: nil)
        @adapter       = adapter
        @state_factory = state_factory
        @storage       = storage || Socrates.config.storage

        @logger        = Socrates.config.logger
        @error_message = Socrates.config.error_message || DEFAULT_ERROR_MESSAGE
      end

      # rubocop:disable Metrics/AbcSize
      def dispatch(message, context: {})
        message = message.strip

        client_id = @adapter.client_id_from_context(context)

        @logger.info %(#{client_id} recv: "#{message}")

        # In many cases, a two actions will run in this loop: :listen => :ask, but it's possible that a chain of 2 or
        # more :ask actions could run, before stopping at a :listen (and waiting for the next input).
        loop do
          state_data = fetch_snapshot(client_id)
          state      = instantiate_state(state_data, context)

          args = [state.data.state_action]
          args << message if state.data.state_action == :listen

          msg = %(#{client_id} processing :#{state.data.state_id} / :#{args.first})
          msg += %( / message: "#{args.second}") if args.count > 1
          @logger.debug msg

          begin
            state.send(*args)
          rescue => e
            handle_action_error(e, client_id, state, context)
            return
          end

          # Update the persisted state data so we know what to run next time.
          state.data.state_id     = state.next_state_id
          state.data.state_action = state.next_state_action

          @logger.debug %(#{client_id} transition to :#{state.data.state_id} / :#{state.data.state_action})

          persist_snapshot(client_id, state.data)

          # Break from the loop if there's nothing left to do, i.e. no more state transitions.
          break if done_transitioning?(state)
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      DEFAULT_ERROR_MESSAGE = "Sorry, an error occurred. We'll have to start over..."

      # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      def fetch_snapshot(client_id)
        if @storage.has_key?(client_id)
          begin
            snapshot   = @storage.get(client_id)
            state_data = StateData.deserialize(snapshot)
          rescue => e
            @logger.warn "Error while fetching snapshot for client id '#{client_id}', resetting state: #{e.message}"
            @logger.warn e
          end
        end

        state_data ||= StateData.new

        # If the current state is nil or END_OF_CONVERSATION, set it to the default state, which is typically a state
        # that waits for an initial command or input from the user (e.g. help, start, etc).
        if state_data.state_id.nil? || state_data.state_id == State::END_OF_CONVERSATION
          default_state, default_action = @state_factory.default

          state_data.state_id     = default_state
          state_data.state_action = default_action || :listen

        # Check to see if the last interation was too long ago.
        elsif state_data_expired?(state_data) && @state_factory.expired(state_data).present?
          expired_state, expired_action = @state_factory.expired(state_data)

          state_data.state_id     = expired_state
          state_data.state_action = expired_action || :ask
        end

        state_data
      end
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

      def persist_snapshot(client_id, state_data)
        state_data.reset_elapsed_time
        @storage.put(client_id, state_data.serialize)
      end

      def state_data_expired?(state_data)
        return unless state_data.timestamp.present?

        state_data.elapsed_time > (Socrates.config.expired_timeout || 30.minutes)
      end

      def instantiate_state(state_data, context)
        @state_factory.build(state_data: state_data, adapter: @adapter, context: context)
      end

      def done_transitioning?(state)
        # Stop transitioning if we're waiting for the user to respond (i.e. we're listening).
        return true if state.data.state_action == :listen

        # Stop transitioning if there's no state to transition to, or the conversation has ended.
        state.data.state_id.nil? || state.data.state_id == State::END_OF_CONVERSATION
      end

      def handle_action_error(e, client_id, state, context)
        @logger.warn "Error while processing action #{state.data.state_id}/#{state.data.state_action}: #{e.message}"
        @logger.warn e

        @adapter.send_message(@error_message, context: context)
        state.data.clear
        state.data.state_id     = nil
        state.data.state_action = nil

        persist_snapshot(client_id, state.data)
      end
    end
  end
end
