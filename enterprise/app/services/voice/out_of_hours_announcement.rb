# What a caller gets outside the inbox's business hours. Twilio plays Captain's recording of the
# announcement, or reads the text when there is none, then takes a voicemail when the inbox allows
# it and hangs up. WhatsApp can't play audio from the server, so the caller gets the announcement as
# a message.
class Voice::OutOfHoursAnnouncement
  VOICEMAIL_MAX_SECONDS = 120

  pattr_initialize [:inbox!]

  def twiml(call)
    Twilio::TwiML::VoiceResponse.new do |response|
      announce(response)
      record_voicemail(response) if inbox.channel.voicemail_enabled? && call.recording_enabled?
      response.hangup
    end.to_s
  end

  def decline_whatsapp_call(call)
    inbox.channel.provider_service.reject_call(call.provider_call_id)
    call.conversation.messages.create!(account_id: inbox.account_id, inbox_id: inbox.id, message_type: :template, content: message)
  end

  private

  def announce(response)
    audio = inbox.out_of_hours_call_audio
    return response.say(message: message) unless audio.attached?

    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    response.play(url: audio.url)
  end

  # The recording reaches the call through the usual recording callback, which attaches and transcribes it.
  # Twilio asks the action URL what to do once recording ends; without one it would replay this announcement.
  def record_voicemail(response)
    phone = inbox.channel.phone_number.delete_prefix('+')
    routes = Rails.application.routes.url_helpers
    response.record(
      max_length: VOICEMAIL_MAX_SECONDS,
      play_beep: true,
      trim: 'trim-silence',
      action: routes.twilio_voice_voicemail_url,
      recording_status_callback: routes.twilio_voice_recording_status_url(phone: phone),
      recording_status_callback_event: 'completed',
      recording_status_callback_method: 'POST'
    )
  end

  def message
    inbox.channel.out_of_hours_call_message
  end
end
