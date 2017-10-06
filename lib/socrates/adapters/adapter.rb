require "socrates/adapters/stubs"

module Socrates
  module Adapters
    module Adapter
      def client_id_from(_context: nil, _user: nil)
        raise NotImplementedError
      end

      def channel_from(_context: nil, _user: nil)
        raise NotImplementedError
      end

      def send_message(_session, _message, _send_now: false) # queue_message?
        raise NotImplementedError
      end

      def send_direct_message(_session, _message, _recipient)
        raise NotImplementedError
      end

      def flush_session(session, channel: nil)
        session.messages.select { |c, _| channel.nil? || channel == c }.each do |c, messages|
          _send_message(c, messages.join("\n\n"))
          messages.clear
        end
      end

      def _send_message(_channel, _message) # TODO: send_message
        raise NotImplementedError
      end

      def user_from(_context:)
        raise NotImplementedError
      end

      def users_list(*)
        raise NotImplementedError
      end

      def lookup_user(_email:)
        raise NotImplementedError
      end

      def lookup_email(*)
        raise NotImplementedError
      end

      def users_channel(_user)
        raise NotImplementedError
      end
    end
  end
end
