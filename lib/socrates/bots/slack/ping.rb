module Socrates
  module Bots
    class Slack
      class Ping
        def initialize
          logger = Logger.new($stdout)
          # The ping is going to run every minute, so don't be too chatty
          logger.level = Logger::WARN

          @client = ::Slack::Web::Client.new(
            token: ENV.fetch("SLACK_API_TOKEN"),
            logger: logger
          )
        end

        def alive?
          auth = client.auth_test
          presence = client.users_getPresence(user: auth["user_id"])
          presence.online?
        end

        private

        attr_reader :client
      end
    end
  end
end
