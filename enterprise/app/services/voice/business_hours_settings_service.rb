# Saves "Apply business hours to calls" and the announcement callers get outside them. On Twilio,
# a new text is recorded with Captain before anything is saved, so callers never hear audio of an
# older text; without Captain, Twilio reads the text instead.
class Voice::BusinessHoursSettingsService
  MESSAGE_MAX_LENGTH = 1000

  pattr_initialize [:inbox!, :enabled!, :message]

  def perform
    @message = message.to_s.strip.presence
    validate!

    channel = inbox.channel
    audio = recorded_audio if channel.is_a?(Channel::TwilioSms) && @message != channel.out_of_hours_call_message
    channel.provider_config = (channel.provider_config || {}).merge('business_hours_calls_enabled' => enabled,
                                                                    'out_of_hours_call_message' => @message)
    channel.save!(validate: false)
    store_audio(audio) unless audio.nil?
  end

  private

  def validate!
    raise ArgumentError, I18n.t('inbox.call_business_hours.message_required') if enabled && @message.nil?
    raise ArgumentError, I18n.t('inbox.call_business_hours.message_too_long') if @message.to_s.length > MESSAGE_MAX_LENGTH
  end

  # The mp3 of the new text, or false when there is nothing to play (no text, or no Captain)
  def recorded_audio
    return false if @message.nil? || !Llm::TextToSpeechService.available_for?(inbox.account)

    Llm::TextToSpeechService.new(text: @message, account: inbox.account).perform
  end

  def store_audio(mp3)
    attachment = inbox.out_of_hours_call_audio
    return attachment.purge unless mp3

    attachment.attach(io: StringIO.new(mp3), filename: "out-of-hours-#{inbox.id}.mp3", content_type: 'audio/mpeg')
  end
end
