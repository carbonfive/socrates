require "socrates/adapters/stubs"

module Socrates
  module Adapters
    class Console
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

      def send_message(message, channel)
        raise ArgumentError, "Channel is required" unless channel.present?

        puts "\n#{colorize(@name, "32;1")}: #{message}"
      end

      def send_direct_message(message, user)
        raise ArgumentError, "User is required" unless user.present?

        name =
          if user.respond_to?(:name)
            user.name
          elsif user.respond_to?(:id)
            user.id
          else
            user
          end

        puts "\n[DM] #{colorize(name, "34;1")}: #{message}"
      end

      private

      def colorize(str, color_code)
        "\e[#{color_code}m#{str}\e[0m"
      end
    end
  end
end
