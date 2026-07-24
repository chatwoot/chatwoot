module Enterprise::ContactInboxBuilder
  private

  def generate_source_id
    return super unless twilio_voice_inbox?

    phone_source_id
  end

  def phone_source_id
    return super unless twilio_voice_inbox?

    return SecureRandom.uuid if @contact.phone_number.blank?

    @contact.phone_number
  end

  def allowed_channels?
    super || twilio_voice_inbox?
  end

  def twilio_voice_inbox?
    @inbox.channel_type == 'Channel::TwilioSms' && @inbox.channel.voice_enabled?
  end
end
