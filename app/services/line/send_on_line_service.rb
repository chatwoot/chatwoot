class Line::SendOnLineService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Line
  end

  def perform_reply
    client.push_message(message.conversation.contact_inbox.source_id, [{type: "text", text: message.content}])
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_id = inbox.channel.line_channel_id
      config.channel_secret = inbox.channel.line_channel_secret
      config.channel_token = inbox.channel.line_channel_token
    }
  end
end
