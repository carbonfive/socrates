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
    # StubUserDirectory provides some simple stub behavior for adding stubbed users and querying against them. This are
    # to be used by stubbed versions of adapters (like Console, Memory, etc).
    #
    module StubUserDirectory
      attr_accessor :email, :users

      def initialize
        @users = []
      end

      # rubocop:disable Metrics/ParameterLists
      def add_user(id: nil, name: nil, first: nil, last: nil, email: nil, tz_offset: 0)
        users << User.new(id, name, tz_offset, Profile.new(first, last, email))
      end
      # rubocop:enable Metrics/ParameterLists

      def users_list(*)
        Response.new(users)
      end

      def lookup_user(email:)
        users.find { |user| user.profile&.email == email }
      end

      def lookup_email(*)
        email
      end
    end
  end
end
