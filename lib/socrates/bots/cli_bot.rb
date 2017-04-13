module Socrates
  module Bots
    class CLIBot
      class TTYClient
        CLIENT_ID = 'tty'

        def client_id_from_context(_context)
          CLIENT_ID
        end

        def send_message(message, _context)
          puts "\n@timesheet: #{message}"
        end
      end

      def initialize(state_factory:)
        @chatbot_client = TTYClient.new
        @storage        = Storage::MemoryStorage.new
        @dispatcher     = Core::Dispatcher.new(storage: @storage, chatbot_client: @chatbot_client, state_factory: state_factory)
      end

      def start
        # Clear out any remnants from previous runs.
        @storage.clear(TTYClient::CLIENT_ID)

        while (input = gets.chomp) do
          @dispatcher.dispatch(message: input)
        end
      end
    end
  end
end
