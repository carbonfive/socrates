require "socrates/adapters/console"
require "socrates/core/dispatcher"

module Socrates
  module Bots
    class CLI
      def initialize(state_factory:, adapter: nil)
        @adapter    = adapter || Adapters::Console.new
        @dispatcher = Core::Dispatcher.new(adapter: @adapter, state_factory: state_factory)
      end

      def start
        context = { channel: "CONSOLE" }

        while (input = gets.chomp)
          @dispatcher.dispatch(input, context: context)
        end
      end
    end
  end
end
