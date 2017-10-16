module Socrates
  module Adapters
    #
    # Response, User, Profile are POROs that represent keys concepts that exist in Slack (or other chat systems).
    #
    Response = Struct.new(:members)

    User = Struct.new(:id, :name, :tz_offset, :profile) do
      def real_name
        return "" if profile.nil?

        "#{profile.first_name} #{profile.last_name}"
      end
    end

    Profile = Struct.new(:first_name, :last_name, :email)

    #
    # StubUserDirectory provides some simple stub behavior for adding stubbed users and querying against them. This is
    # to be used by the stubbed versions of adapters (like Console and Memory).
    #
    module StubUserDirectory
      attr_accessor :default_user, :users

      def initialize
        @users = []
      end

      # rubocop:disable Metrics/ParameterLists
      def add_user(id: nil, name: nil, first: nil, last: nil, email: nil, tz_offset: 0)
        User.new(id, name, tz_offset, Profile.new(first, last, email)).tap do |new_user|
          @users << new_user
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def user_from(*)
        @default_user
      end

      def users_list(*)
        Response.new(@users)
      end

      def lookup_user(email:)
        @users.find { |user| email == user.profile&.email }
        Response.new(@users).members
      end

      def lookup_email(*)
        @default_user.profile&.email
      end
    end
  end
end
