module Enterprise::Messages::MessageBuilder
  private

  def message_type
    return @message_type if @message_type == 'incoming' && @conversation.inbox.channel_type == 'Channel::Voice'

    super
  end
end
