module Enterprise::Messages::MessageBuilder
  private

  def message_type
    # Allow incoming messages in API and Voice inboxes
    if !['Channel::Api', 'Channel::Voice'].include?(@conversation.inbox.channel_type) && @message_type == 'incoming'
      raise StandardError, 'Incoming messages are only allowed in Api and Voice inboxes'
    end
    @message_type
  end
end

