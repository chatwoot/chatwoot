module Enterprise::ContactInbox
  ANONYMOUS_CALL_SOURCE_ID = /\Aanonymous:CA[0-9a-f]{32}\z/i

  def anonymous_caller?
    inbox.channel_type == 'Channel::TwilioSms' && ANONYMOUS_CALL_SOURCE_ID.match?(source_id.to_s)
  end

  private

  def validate_twilio_source_id
    return if inbox.channel.voice_enabled? && anonymous_caller?

    super
  end
end
