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
        @adapter      = SlackAdapter.new(@slack_client)
        @dispatcher   = Core::Dispatcher.new(adapter: @adapter, state_factory: state_factory)
      end

      def start
        @slack_client.on :message do |data|
          # puts "> #{data}"

          # When first connecting, Slack may resend the last message. Ignore it...
          next if data.reply_to.present?

          @dispatcher.dispatch(message: data.text, context: data)
        end

        @slack_client.start!
      end
    end
  end
end
