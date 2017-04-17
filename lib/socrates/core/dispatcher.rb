require "hashie"

require "socrates/logger"
require "socrates/string_helpers"
require "socrates/storage/storage"
require "socrates/core/state_data"

module Socrates
  module Core
    class Dispatcher
      def initialize(adapter:, state_factory:, storage: nil)
        @adapter       = adapter
        @state_factory = state_factory
        @storage       = storage || Storage::MemoryStorage.new

        @logger        = Socrates::Config.logger || Socrates::Logger.default
        @error_message = Socrates::Config.error_message || DEFAULT_ERROR_MESSAGE
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def dispatch(message:, context: {})
        client_id = @adapter.client_id_from_context(context)

        message = message.strip

        @logger.info %(#{client_id} received: "#{message}")

        # In many cases, a single state will run in this loop, but it's possible that a chain of 2 or more :say
        # actions could run, before stopping at a listen (and waiting for the next input).
        loop do
          state_data = fetch_snapshot(client_id)
          state      = instantiate_state(state_data, context)

          args = [state.data.state_action]
          args << message if state.data.state_action == :listen

          begin
            state.send(*args)
          rescue => e
            @logger.warn "Error while processing action #{state.data.state_id}/#{state.data.state_action}: #{e.message}"
            @logger.warn e

            @adapter.send_message(@error_message, context)
            state.data.clear
            state.data.state_id     = nil
            state.data.state_action = nil
            persist_snapshot(client_id, state.data)
            return
          end

          # Update the persisted state data so we know what to run next time.
          state.data.state_id     = state.next_state_id
          state.data.state_action = state.next_state_action

          persist_snapshot(client_id, state.data)

          # Break from the loop if there's nothing left to do, i.e. no more state transitions.
          break if done_transitioning?(state)
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      private

      DEFAULT_ERROR_MESSAGE = "Sorry, an error occurred. We'll have to start over..."

      def fetch_snapshot(client_id)
        state_data =
          if @storage.has_key?(client_id)
            begin
              snapshot = @storage.get(client_id)
              StateData.deserialize(snapshot)
            rescue => e
              @logger.warn "Error while fetching snapshot for client id '#{client_id}', resetting state: #{e.message}"
              @logger.warn e

              StateData.new
            end
          else
            StateData.new
          end

        # If the current state is nil, set it to the default state, which is typically a state that waits for an
        # initial command or input from the user (e.g. help, start, etc).
        if state_data.state_id.nil?
        # If the current state is nil or END_OF_CONVERSATION, set it to the default state, which is typically a state
        # that waits for an initial command or input from the user (e.g. help, start, etc).
        if state_data.state_id.nil? || state_data.state_id == State::END_OF_CONVERSATION
          state_data.state_id     = @state_factory.default_state
          state_data.state_action = :listen
        end

        state_data
      end

      def persist_snapshot(client_id, state_data)
        @storage.put(client_id, state_data.serialize)
      end

      def instantiate_state(state_data, context)
        @state_factory.build(state_data: state_data, adapter: @adapter, context: context)
      end

      def done_transitioning?(state)
        # Stop transitioning if we're waiting for the user to respond (i.e. we're listening).
        return true if state.data.state_action == :listen

        # Stop transitioning if there's no state to transition to, or the conversation has ended.
        return true if state.data.state_id.nil? || state.data.state_id == State::END_OF_CONVERSATION

        false
      end
    end
  end
end
