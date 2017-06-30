require "active_support/core_ext/object"

module Socrates
  module Adapters
    class Slack
      def initialize(real_time_client)
        @real_time_client = real_time_client
      end

      def client_id_from(context: nil, user: nil)
        unless context.nil?
          raise ArgumentError, "Expected :context to respond to :user" unless context.respond_to?(:user)
          return context.user
        end
        unless user.nil?
          raise ArgumentError, "Expected :user to respond to :id" unless user.respond_to?(:id)
          return user.id
        end
        raise ArgumentError, "Must provide one of :context or :user"
      end

      def channel_from(context: nil, user: nil)
        unless context.nil?
          raise ArgumentError, "Expected :context to respond to :channel" unless context.respond_to?(:channel)
          return context.channel
        end
        unless user.nil?
          # raise ArgumentError, "Expected :user to respond to :id" unless user.respond_to?(:id)
          return lookup_im_channel(user)
        end
        raise ArgumentError, "Must provide one of :context or :user"
      end

      def send_message(message, channel)
        @real_time_client.message(text: message, channel: channel)
      end

      def send_direct_message(message, user)
        raise ArgumentError, "Expected user to respond to :id" unless user.respond_to?(:id)

        im_channel = lookup_im_channel(user)

        @real_time_client.message(text: message, channel: im_channel)
      end

      def users_list(include_deleted: false, include_bots: false)
        client = @real_time_client.web_client

        client.users_list.tap do |response|
          response.members.reject!(&:deleted?) unless include_deleted
          response.members.reject!(&:is_bot?) unless include_bots
        end
      end

      # Note: this triggers a call to the Slack API which makes it ill-suited for use within a loop.
      def lookup_user(email:)
        users_list.members.find { |user| email == user.profile&.email }
      end

      def lookup_email(context:)
        raise ArgumentError, "Expected :context to respond to :user" unless context.respond_to?(:user)

        client = @real_time_client.web_client
        info   = client.users_info(user: context.user)
        info.present? ? info.user.profile.email.presence : nil
      end

      private

      def lookup_im_channel(user)
        im = @real_time_client.ims.values.find { |i| i.user == user }

        return im if im.present?

        # Start a new conversation with this user.
        response = @real_time_client.web_client.im_open(user: user.id)
        response.channel.id
      end
    end
  end
end
