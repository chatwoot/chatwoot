# What a caller gets outside the inbox's business hours. Twilio plays Captain's recording of the
# announcement, or reads the text when there is none, then hangs up. WhatsApp can't play audio from
# the server, so the caller gets the announcement as a message.
class Voice::OutOfHoursAnnouncement
  pattr_initialize [:inbox!]

  def twiml
    audio = inbox.out_of_hours_call_audio
    Twilio::TwiML::VoiceResponse.new do |response|
      if audio.attached?
        ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
        response.play(url: audio.url)
      else
        response.say(message: message)
      end
      response.hangup
    end.to_s
  end

  def decline_whatsapp_call(call)
    inbox.channel.provider_service.reject_call(call.provider_call_id)
    call.conversation.messages.create!(account_id: inbox.account_id, inbox_id: inbox.id, message_type: :template, content: message)
  end

  private

  def message
    inbox.channel.out_of_hours_call_message
  end
end
