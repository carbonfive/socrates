require "active_support/core_ext/object"
require "socrates/adapters/adapter"

module Socrates
  module Adapters
    class Slack
      include Socrates::Adapters::Adapter

      def initialize(real_time_client)
        @real_time_client = real_time_client
      end

      def client_id_from(context: nil, user: nil)
        unless context.nil?
          raise ArgumentError, "Expected context to respond to :user" unless context.respond_to?(:user)
          return context.user
        end
        unless user.nil?
          raise ArgumentError, "Expected user to respond to :id" unless user.respond_to?(:id)
          return user.id
        end
        raise ArgumentError, "Must provide one of context or user"
      end

      def channel_from(context: nil, user: nil)
        unless context.nil?
          raise ArgumentError, "Expected context to respond to :channel" unless context.respond_to?(:channel)
          return context.channel
        end
        return lookup_dm_channel(user) unless user.nil?

        raise ArgumentError, "Must provide one of context or user"
      end

      def users(include_deleted: false, include_bots: false)
        client = @real_time_client.web_client

        client.users_list.tap { |response|
          response.members.reject!(&:deleted?) unless include_deleted
          response.members.reject!(&:is_bot?) unless include_bots
        }.members
      end

      def user_from(context:)
        raise ArgumentError, "context cannot be nil" if context.nil?
        raise ArgumentError, "Expected context to respond to :user" unless context.respond_to?(:user)

        client = @real_time_client.web_client
        info   = client.users_info(user: context.user)
        info.present? ? info.user : nil
      end

      def lookup_email(context:)
        raise ArgumentError, "Expected context to respond to :user" unless context.respond_to?(:user)

        client = @real_time_client.web_client
        info   = client.users_info(user: context.user)
        info.present? ? info.user.profile.email.presence : nil
      end

      private

      def send_message(channel, message)
        @real_time_client.message(text: message, channel: channel)
      end

      def lookup_dm_channel(user)
        im = @real_time_client.ims.values.find { |i| i.user == user }

        return im if im.present?

        # Start a new conversation with this user.
        response = @real_time_client.web_client.im_open(user: user.id)
        response.channel.id
      end
    end
  end
end
