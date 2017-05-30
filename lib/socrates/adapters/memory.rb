require "socrates/adapters/stubs"

module Socrates
  module Adapters
    class Memory
      include StubUserDirectory

      CLIENT_ID = "MEMORY"
      CHANNEL   = "C1"

      attr_reader :history

      def initialize
        super()
        @history = Hash.new { |hash, key| hash[key] = [] }
      end

      def client_id_from(context: nil, user: nil)
        raise ArgumentError, "Must provide one of :context or :user" if context.nil? && user.nil?

        CLIENT_ID
      end

      def channel_from(context: nil, user: nil)
        raise ArgumentError, "Must provide one of :context or :user" if context.nil? && user.nil?

        user.nil? ? CHANNEL : users_channel(user)
      end

      def send_message(message, channel)
        raise ArgumentError, "Channel is required" unless channel.present?

        @history[channel] << message
      end

      def send_direct_message(message, user)
        raise ArgumentError, "User is required" unless user.present?

        @history[users_channel(user)] << message
      end

      #
      # Methods for fetching messages and dms in specs...
      #

      def msgs
        @history[CHANNEL]
      end

      def last_msg
        msgs[-1]
      end

      def dms(user)
        @history[users_channel(user)]
      end

      def last_dm(user)
        dms(user)[-1]
      end

      private

      def users_channel(user)
        user.respond_to?(:id) ? user.id : user
      end
    end
  end
end
