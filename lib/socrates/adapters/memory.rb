require "socrates/adapters/stubs"

module Socrates
  module Adapters
    class Memory
      include StubUserDirectory

      CLIENT_ID = "MEMORY"

      attr_reader :history, :dms

      def initialize
        super()

        @history = []
        @dms     = Hash.new { |hash, key| hash[key] = [] }
      end

      def client_id_from_context(_context)
        CLIENT_ID
      end

      def send_message(message, *)
        @history << message
      end

      def send_direct_message(message, user, *)
        user = user.id if user.respond_to?(:id)

        @dms[user] << message
      end

      def last_message
        @history.last
      end
    end
  end
end
