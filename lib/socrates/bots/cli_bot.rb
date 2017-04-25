module Socrates
  module Bots
    class CLIBot
      def initialize(adapter: nil, state_factory:)
        @adapter    = adapter || Adapters::ConsoleAdapter.new
        @dispatcher = Core::Dispatcher.new(adapter: @adapter, state_factory: state_factory)
      end

      def start
        while (input = gets.chomp)
          @dispatcher.dispatch(message: input)
        end
      end
    end
  end
end
