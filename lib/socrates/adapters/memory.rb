require "socrates/adapters/adapter"
require "socrates/adapters/stubs"

module Socrates
  module Adapters
    class Memory
      include Socrates::Adapters::Adapter
      include StubUserDirectory

      CLIENT_ID = "MEMORY"
      CHANNEL   = "C1"

      attr_reader :history
      attr_accessor :client_id

      def initialize
        super()
        @history = Hash.new { |hash, key| hash[key] = [] }
      end

      def client_id_from(context: nil, user: nil)
        raise ArgumentError, "Must provide one of :context or :user" if context.nil? && user.nil?

        @client_id || CLIENT_ID
      end

      def channel_from(context: nil, user: nil)
        raise ArgumentError, "Must provide one of :context or :user" if context.nil? && user.nil?

        user.nil? ? CHANNEL : users_channel(user)
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

      def send_message(channel, message)
        @history[channel] << message
      end

      def users_channel(user)
        user.respond_to?(:id) ? user.id : user
      end
    end
  end
end
