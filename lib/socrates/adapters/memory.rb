require "socrates/adapters/stubs"

module Socrates
  module Adapters
    class Memory
      CLIENT_ID = "MEMORY"

      attr_reader :history, :dms
      attr_accessor :email, :users

      def initialize
        @history = []
        @dms     = Hash.new { |hash, key| hash[key] = [] }
        @users   = []
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

      def add_user(id: nil, name: nil, first: nil, last: nil, email: nil)
        users << User.new(id, name, Profile.new(first, last, email))
      end

      def users_list(*)
        Response.new(users)
      end

      def lookup_email(*)
        email
      end
    end
  end
end
