require "socrates/adapters/adapter"
require "socrates/adapters/stubs"

module Socrates
  module Adapters
    class Console
      include Socrates::Adapters::Adapter
      include StubUserDirectory

      CLIENT_ID = "CONSOLE"

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

        if context&.fetch(:channel).present?
          context[:channel]
        elsif user.present?
          display_user(user)
        else
          "?"
        end
      end

      private

      def display_user(user)
        (user&.name || user&.id || user)&.upcase
      end

      def send_message(channel, message)
        puts "\n#{colorize(channel, "34;1")}: #{message}"
      end

      def colorize(str, color_code)
        "\e[#{color_code}m#{str}\e[0m"
      end
    end
  end
end
