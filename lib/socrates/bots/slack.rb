require "slack-ruby-client"

require "socrates/adapters/slack"
require "socrates/core/dispatcher"

module Socrates
  module Bots
    class Slack
      def initialize(state_factory:)
        ::Slack.configure do |config|
          config.token        = ENV["SLACK_API_TOKEN"]
          config.logger       = Logger.new($stdout)
          config.logger.level = Logger::INFO

          raise "Missing ENV['SLACK_API_TOKEN']!" unless config.token
        end

        @slack_client = ::Slack::RealTime::Client.new
        @adapter      = Adapters::Slack.new(@slack_client)
        @dispatcher   = Core::Dispatcher.new(adapter: @adapter, state_factory: state_factory)
      end

      def start
        @slack_client.on :message do |data|
          # puts "> #{data}"

          # Slack sends us messages from ourslves sometimes, this skips them.
          next if @slack_client.self.id == data.user

          @dispatcher.dispatch(data.text, context: data)
        end

        @slack_client.start_async

        ping = Ping.new
        loop do
          sleep 60
          next if ping.alive?

          alert "Slack RTC has gone offline; restarting it"
          @slack_client.stop! if @slack_client.started?
          sleep 1 # give the websocket a chance to completely disconnect
          @slack_client.start_async
        end
      end

      private

      def alert(message)
        Socrates.config.logger.warn(message)
        Socrates.config.warn_handler.call(message)
      end
    end
  end
end
