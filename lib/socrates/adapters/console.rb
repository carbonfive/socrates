require "socrates/adapters/stubs"

module Socrates
  module Adapters
    class Console
      include Socrates::Adapters::Adapter
      include StubUserDirectory

      CLIENT_ID = "CONSOLE"
      CHANNEL   = "C1"

      def initialize(name: "@socrates")
        super()
        @name = name
      end

      def client_id_from(context: nil, user: nil)
        raise ArgumentError, "Must provide one of :context or :user" if context.nil? && user.nil?

        CLIENT_ID
      end

      def channel_from(context: nil, user: nil)
        raise ArgumentError, "Must provide one of :context or :user" if context.nil? && user.nil?

        CHANNEL
      end

      def send_message(session, message, send_now: false)
        raise ArgumentError, "Channel is required" unless session.channel.present?

        session.messages[session.channel] << message
        flush_session(session, channel: session.channel) if send_now
      end

      def send_direct_message(session, message, recipient)
        raise ArgumentError, "User is required" unless recipient.present?

        name =
          if recipient.respond_to?(:name)
            recipient.name
          elsif recipient.respond_to?(:id)
            recipient.id
          else
            recipient
          end

        session.messages[name] << message
      end

      private

      def _send_message(channel, message) # TODO: Underscored name?
        puts "\n#{colorize(channel, "34;1")}: #{message}"
      end

      def colorize(str, color_code)
        "\e[#{color_code}m#{str}\e[0m"
      end
    end
  end
end
