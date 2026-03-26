module Enterprise::Messages::MessageBuilder
  private

  def message_type
    return @message_type if @message_type == 'incoming' && twilio_voice_inbox?

    super
  end

  def twilio_voice_inbox?
    inbox = @conversation.inbox
    inbox.channel_type == 'Channel::TwilioSms' && inbox.channel.voice_enabled?
  end
end
