module Enterprise::Messages::MessageBuilder
  private

  def message_type
    # Allow incoming messages in API and Voice inboxes
    if @message_type == 'incoming' &&
       ['Channel::Api', 'Channel::Voice'].exclude?(@conversation.inbox.channel_type)
      raise StandardError, 'Incoming messages are only allowed in Api and Voice inboxes'
    end

    @message_type
  end
end
