require "hashie"
require "erb"

module Socrates
  module Core
    module State
      attr_reader :data, :context

      def initialize(data: StateData.new, adapter:, context: nil)
        @data              = data
        @adapter           = adapter
        @context           = context
        @next_state_id     = UNSET_VALUE
        @next_state_action = UNSET_VALUE
      end

      def next_state_id
        if @next_state_id == UNSET_VALUE
          state_id_from_classname
        else
          @next_state_id
        end
      end

      def next_state_action
        if @next_state_action == UNSET_VALUE
          next_action(@data.state_action)
        else
          @next_state_action
        end
      end

      def respond(message: nil, template: nil)
        if template
          # TODO: Partials?
          filename = File.join(Socrates.config.view_path, template)
          source   = File.read(filename)
          message  = ERB.new(source, 0, "<>").result(binding)
        end

        @adapter.send_message(message, @context) if message
      end

      def transition_to(state_id, action: nil, data: {})
        if action.nil?
          action =
            if state_id.nil?
              nil
            elsif state_id == state_id_from_classname
              next_action(@data.current_action)
            else
              :say
            end
        end

        @next_state_id     = state_id
        @next_state_action = action

        @data.merge(data)
      end

      def repeat_action
        @next_state_id     = @data.state_id
        @next_state_action = @data.state_action
      end

      def end_conversation
        @data.clear

        transition_to nil
      end

      def say
        # stub implementation, to be overwritten.
      end

      def listen(_message)
        # stub implementation, to be overwritten.
      end

      private

      UNSET_VALUE = :noop # TODO: Flip this and use it to indicate END OF CONVERSAION?

      def next_action(current_action)
        (%i[say listen] - [current_action]).first
      end

      def state_id_from_classname
        StringHelpers.classname_to_underscore(self.class.to_s.split("::").last).to_sym
      end
    end
  end
end
