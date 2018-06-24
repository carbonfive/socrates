require "date"

require "socrates/string_helpers"
require "socrates/core/state"

module Socrates
  module SampleStates
    class StateFactory
      def default
        :get_started
      end

      def expired(*)
        :expired
      end

      def build(state_data:, adapter:, session:)
        classname = StringHelpers.underscore_to_classname(state_data.state_id)

        Object.const_get("Socrates::SampleStates::#{classname}")
          .new(data: state_data, adapter: adapter, session: session)
      end
    end

    class GetStarted
      include Socrates::Core::State

      def listen(message)
        case message.downcase
          when "help"
            transition_to :help
          when "age"
            transition_to :ask_for_name
          when "dms"
            transition_to :dms
          when "error"
            transition_to :raise_error
          else
            transition_to :no_comprende
        end
      end
    end

    class Help
      include Socrates::Core::State

      def ask
        respond message: <<~MSG
          Thanks for asking! I can do these things for you...

            • `age` - Calculate your age from your birth date.
            • `dms` - Sends a direct messages to two other users.
            • `error` - Start a short error path that raises an error.
            • `help` - Tell you what I can do for you.

          So, what shall it be?
        MSG

        transition_to :get_started, action: :listen
      end
    end

    class NoComprende
      include Socrates::Core::State

      def ask
        respond message: "Whoops, I don't know what you mean by that. Try `help` to see my commands."

        transition_to :get_started
      end
    end

    class Expired
      include Socrates::Core::State

      def ask
        respond message: "I've forgotten what we're talking about, let's start over."

        transition_to :help
      end
    end

    class AskForName
      include Socrates::Core::State

      def ask
        respond message: "First things first, what's your name?"
      end

      def listen(message)
        transition_to :ask_for_birth_date, data: { name: message }
      end
    end

    class AskForBirthDate
      include Socrates::Core::State

      def ask
        respond message: "Hi #{first_name}! What's your birth date (e.g. MM/DD/YYYY)?"
      end

      def listen(message)
        begin
          birth_date = Date.strptime(message, "%m/%d/%Y")
        rescue ArgumentError
          respond message: "Whoops, I didn't understand that. What's your birth date (e.g. MM/DD/YYYY)?"
          repeat_action
          return
        end

        transition_to :calculate_age, data: { birth_date: birth_date }
      end

      private

      def first_name
        @data.get(:name).split.first
      end
    end

    class CalculateAge
      include Socrates::Core::State

      def ask
        respond message: "Got it #{first_name}! So that makes you #{calculate_age} years old."

        # Example of a :ask => :ask transition.
        transition_to :end_conversation_1
      end

      private

      def first_name
        @data.get(:name).split.first
      end

      def birth_date
        @data.get(:birth_date)
      end

      def calculate_age
        today = Time.current.to_date

        age = today.year - birth_date.year
        age -= 1 if today.month < birth_date.month || (today.month == birth_date.month && birth_date.day > today.day)

        age
      end
    end

    class EndConversation1
      include Socrates::Core::State

      def ask
        respond message: "That's all for now..."

        # Example of another :ask => :ask transition.
        transition_to :end_conversation_2
      end
    end

    class EndConversation2
      include Socrates::Core::State

      def ask
        respond message: "Type `help` to see what else I can do."

        end_conversation
      end
    end

    class Dms
      include Socrates::Core::State

      def ask
        respond message: "I will send whatever you type to two other users as direct messages."
      end

      def listen(message)
        users = @adapter.users.sample(2)

        users.each do |user|
          send_message(to: user, message: "Message: #{message}")
        end

        respond message: "Direct messages sent!"

        end_conversation
      end
    end

    class RaiseError
      include Socrates::Core::State

      def ask
        respond message: "I will raise an error regardless of what you enter next..."
      end

      def listen(_message)
        raise ArgumentError, "Boom!"
      end
    end
  end
end
