class SlackAdapter
  def initialize(slack_real_time_client)
    @slack_real_time_client = slack_real_time_client
  end

  def client_id_from_context(context)
    context&.user
  end

  def send_message(message, context)
    @slack_real_time_client.message(text: message, channel: context.channel)
  end
end
