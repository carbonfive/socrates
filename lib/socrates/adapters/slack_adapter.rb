module Socrates
  module Adapters
    class SlackAdapter
      def initialize(real_time_client)
        @real_time_client = real_time_client
      end

      def client_id_from_context(context)
        context&.user
      end

      def send_message(message, context:)
        @real_time_client.message(text: message, channel: context.channel)
      end

      def send_direct_message(message, user, *)
        user = user.id if user.respond_to?(:id)

        im_channel = lookup_im_channel(user)

        @real_time_client.message(text: message, channel: im_channel)
      end

      def users_list
        client = @real_time_client.web_client
        client.users_list
      end

      def lookup_email(context:)
        client = @real_time_client.web_client
        info = client.users_info(user: context.user)
        info.present? ? info.user.profile.email : nil
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
