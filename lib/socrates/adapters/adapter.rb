require "socrates/adapters/stubs"

module Socrates
  module Adapters
    module Adapter
      # Many of the methods in the Adapter module serve as an interface for Adapter implementations to
      # implement. We want to serve as an example, even if we don't provide implementations here.

      def client_id_from(context: nil, user: nil)
        raise NotImplementedError
      end

      def channel_from(context: nil, user: nil)
        raise NotImplementedError
      end

      def queue_message(session, message, send_now: false)
        raise ArgumentError, "session is required" unless session.present?
        raise ArgumentError, "session.channel is required" unless session.channel.present?

        session.messages[session.channel] << message
        flush_session(session, channel: session.channel) if send_now
      end

      def queue_direct_message(session, message, recipient)
        raise ArgumentError, "recipient is required" unless recipient.present?
        raise ArgumentError, "recipient.id is required" unless recipient.id.present?

        dm_channel = channel_from(user: recipient)

        session.messages[dm_channel] << message
      end

      def flush_session(session, channel: nil)
        session.messages.select { |c, _| channel.nil? || channel == c }.each do |c, messages|
          send_message(c, messages.join("\n\n"))
          messages.clear
        end
      end

      def send_message(channel, message)
        raise NotImplementedError
      end

      def users(include_deleted: false, include_bots: false)
        raise NotImplementedError
      end

      def user_from(context:)
        raise NotImplementedError
      end

      def lookup_user(email:)
        users.members.find { |user| email == user.profile&.email }
      end

      def lookup_email(*)
        raise NotImplementedError
      end
    end
  end
end
