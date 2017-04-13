require 'slack-ruby-client'

module Socrates
  module Bots
    class SlackBot
      class SlackClient
        def initialize(slack_real_time_client)
          @slack_real_time_client = slack_real_time_client
        end

        def client_id_from_context(context)
          context.user
        end

        def send_message(message, context)
          @slack_real_time_client.message text: message, channel: context.channel
        end
      end

      def initialize(state_factory:)
        Slack.configure do |config|
          config.token        = ENV['SLACK_API_TOKEN']
          config.logger       = Logger.new(STDOUT)
          config.logger.level = Logger::INFO

          fail "Missing ENV[SLACK_API_TOKEN]!" unless config.token
        end

        @slack_client   = Slack::RealTime::Client.new
        @chatbot_client = SlackClient.new(@slack_client)
        @storage        = Storage::RedisStorage.new
        @dispatcher     = Core::Dispatcher.new(storage: @storage, chatbot_client: @chatbot_client, state_factory: state_factory)
      end

      def start
        @slack_client.on :message do |data|
          # puts "> #{data}"

          @dispatcher.dispatch(message: data.text, context: data)
        end

        @slack_client.start!
      end
    end
  end
end
