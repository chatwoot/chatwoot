module Enterprise::Messages::MessageBuilder
  private

  INCOMING_ALLOWED_CHANNEL_TYPES = %w[Channel::Voice Channel::Whatsapp].freeze

  def message_type
    return @message_type if @message_type == 'incoming' && INCOMING_ALLOWED_CHANNEL_TYPES.include?(@conversation.inbox.channel_type)

    super
  end
end
