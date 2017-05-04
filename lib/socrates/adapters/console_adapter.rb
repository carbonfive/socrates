require "socrates/adapters/stubs"

module Socrates
  module Adapters
    class ConsoleAdapter
      CLIENT_ID = "CONSOLE"

      attr_accessor :email, :users

      def initialize(name: "@socrates")
        @name  = name
        @users = []
      end

      def client_id_from_context(_context)
        CLIENT_ID
      end

      def send_message(message, *)
        puts "\n#{colorize(@name, "32;1")}: #{message}"
      end

      def send_direct_message(message, user, *)
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

      def add_user(id: nil, name: nil, first: nil, last: nil, email: nil)
        users << User.new(id, name, Profile.new(first, last, email))
      end

      def users_list(*)
        Response.new(users)
      end

      def lookup_email(*)
        email
      end

      private

      def colorize(str, color_code)
        "\e[#{color_code}m#{str}\e[0m"
      end
    end
  end
end
