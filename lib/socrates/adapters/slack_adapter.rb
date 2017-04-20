class SlackAdapter
  def initialize(slack_real_time_client)
    @slack_real_time_client = slack_real_time_client
  end

  def client_id_from_context(context)
    context&.user
  end

  def send_message(message, context:)
    @slack_real_time_client.message(text: message, channel: context.channel)
  end

  def send_direct_message(message, user, *)
    user = user.id if user.respond_to?(:id)

    im_channel = lookup_im_channel(user)

    @slack_real_time_client.message(text: message, channel: im_channel)
  end

  private

  def lookup_im_channel(user)
    im = @slack_real_time_client.ims.values.find { |i| i.user == user }

    return im if im.present?

    # Start a new conversation with this user.
    response = @slack_real_time_client.web_client.im_open(user: user.id)
    response.channel.id
  end
end
