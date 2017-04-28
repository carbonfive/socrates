require "slack-ruby-client"

module Socrates
  module Bots
    class SlackBot
      def initialize(state_factory:)
        Slack.configure do |config|
          config.token        = ENV["SLACK_API_TOKEN"]
          config.logger       = Logger.new(STDOUT)
          config.logger.level = Logger::INFO

          raise "Missing ENV['SLACK_API_TOKEN']!" unless config.token
        end

        @slack_client = Slack::RealTime::Client.new
        @adapter      = Adapters::SlackAdapter.new(@slack_client)
        @dispatcher   = Core::Dispatcher.new(adapter: @adapter, state_factory: state_factory)
      end

      def start
        reply_to_messages = {}

        @slack_client.on :message do |data|
          # puts "> #{data}"

          if data.reply_to.present?
            # Stash this message away because we may need it later.
            reply_to_messages[data.channel] = data.text
          end

          # Only dispatch the message if it does not match a previous reply_to message for the channel.
          if reply_to_messages[data.channel] != data.text
            @dispatcher.dispatch(data.text, context: data)
          end
        end

        @slack_client.start!
      end
    end
  end
end
