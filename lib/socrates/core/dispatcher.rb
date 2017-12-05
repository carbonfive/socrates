require "hashie"
require "active_support/all"

require "socrates/configuration"
require "socrates/logger"
require "socrates/string_helpers"
require "socrates/storage/memory"
require "socrates/core/session"
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

      def dispatch(message, context: {})
        client_id = @adapter.client_id_from(context: context)
        channel   = @adapter.channel_from(context: context)
        user      = @adapter.user_from(context: context)

        session = Session.new(client_id: client_id, channel: channel, user: user)

        do_dispatch(session, message)
      end

      def start_conversation(user, state_id, message: nil)
        client_id = @adapter.client_id_from(user: user)
        channel   = @adapter.channel_from(user: user)

        session = Session.new(client_id: client_id, channel: channel, user: user)

        # Now, we assume the user of this code does this check on their own...
        # return false unless conversation_state(user).nil?

        # Create state data to match the request.
        state_data = StateData.new(state_id: state_id, state_action: :ask)

        persist_state_data(session.client_id, state_data)

        # Send our initial message if one was passed to us.
        @adapter.queue_direct_message(session, message, user) if message.present?

        do_dispatch(session, nil)
        true
      end

      def conversation_state(user)
        client_id = @adapter.client_id_from(user: user)

        return nil unless @storage.has_key?(client_id)

        state_data = @storage.fetch(client_id)
        state_data = nil if state_data&.expired? || state_data&.finished?

        state_data
      end

      private

      DEFAULT_ERROR_MESSAGE = "Sorry, an error occurred. We'll have to start over..."

      # rubocop:disable Metrics/AbcSize
      def do_dispatch(session, message)
        message = message&.strip

        @logger.info %Q(#{session.client_id} recv: "#{message}")

        # In many cases, a two actions will run in this loop: :listen => :ask, but it's possible that a chain of 2 or
        # more :ask actions could run, before stopping at a :listen (and waiting for the next input).
        loop do
          state_data = fetch_state_data(session.client_id)
          state      = instantiate_state(session, state_data)

          args = [state.data.state_action]
          args << message if state.data.state_action == :listen

          msg = "#{session.client_id} processing :#{state.data.state_id} / :#{args.first}"
          msg += %Q( / message: "#{args.second}") if args.count > 1
          @logger.debug msg

          begin
            state.send(*args)
          rescue StandardError => e
            handle_action_error(e, session, state)
            return
          end

          # Update the persisted state data so we know what to run next time.
          state.data.state_id     = state.next_state_id
          state.data.state_action = state.next_state_action

          @logger.debug "#{session.client_id} transition to :#{state.data.state_id} / :#{state.data.state_action}"

          persist_state_data(session.client_id, state.data)

          # Break from the loop if there's nothing left to do, i.e. no more state transitions.
          break if done_transitioning?(state)
        end
        # rubocop:enable Metrics/AbcSize

        # Flush the session, which contains any not-yet-send messages.
        @adapter.flush_session(session)
      end

      # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      def fetch_state_data(client_id)
        state_data = @storage.fetch(client_id) || StateData.new

        # If the current state is nil or END_OF_CONVERSATION, set it to the default state, which is typically a state
        # that waits for an initial command or input from the user (e.g. help, start, etc).
        if state_data.state_id.nil? || state_data.state_id == StateData::END_OF_CONVERSATION
          default_state, default_action = @state_factory.default

          state_data.state_id     = default_state
          state_data.state_action = default_action || :listen

        # Check to see if the last interation was too long ago.
        elsif state_data.expired? && @state_factory.expired(state_data).present?
          expired_state, expired_action = @state_factory.expired(state_data)

          state_data.state_id     = expired_state
          state_data.state_action = expired_action || :ask
        end

        state_data
      end
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

      def persist_state_data(client_id, state_data)
        @storage.persist(client_id, state_data)
      end

      def instantiate_state(session, state_data)
        @state_factory.build(state_data: state_data, adapter: @adapter, session: session)
      end

      def done_transitioning?(state)
        # Stop transitioning if we're waiting for the user to respond (i.e. we're listening).
        return true if state.data.state_action == :listen

        # Stop transitioning if there's no state to transition to, or the conversation has ended.
        state.data.state_id.nil? || state.data.state_id == StateData::END_OF_CONVERSATION
      end

      def handle_action_error(e, session, state)
        @logger.warn "Error while processing action #{state.data.state_id}/#{state.data.state_action}: #{e.message}"
        @logger.warn e

        @adapter.queue_message(session, @error_message, send_now: true)

        state.data.clear
        state.data.state_id     = nil
        state.data.state_action = nil

        persist_state_data(session.client_id, state.data)
      end
    end
  end
end
