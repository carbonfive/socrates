require "socrates/adapters/stubs"

module Socrates
  module Adapters
    class Memory
      include StubUserDirectory

      CLIENT_ID = "MEMORY"
      CHANNEL   = "C1"

      attr_reader :history, :dms

      def initialize
        super()
        @history = []
        @dms     = Hash.new { |hash, key| hash[key] = [] }
      end

      def client_id_from(context: nil, user: nil)
        raise ArgumentError, "Must provide one of :context or :user" if context.nil? && user.nil?

        CLIENT_ID
      end

      def channel_from(context: nil, user: nil)
        raise ArgumentError, "Must provide one of :context or :user" if context.nil? && user.nil?

        CHANNEL
      end

      def send_message(message, channel)
        raise ArgumentError, "Channel is required" unless channel.present?

        @history << message
      end

      def send_direct_message(message, user)
        raise ArgumentError, "User is required" unless user.present?

        user = user.id if user.respond_to?(:id)

        @dms[user] << message
      end

      def last_message
        @history.last
      end
    end
  end
end
