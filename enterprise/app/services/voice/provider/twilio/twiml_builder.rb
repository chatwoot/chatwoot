# The TwiML the voice webhooks answer with, for one inbox and the leg Twilio asks about: an
# agent's browser connection (`from` is `client:agent-…`) or the contact's phone
class Voice::Provider::Twilio::TwimlBuilder
  # The playlist Twilio plays to a waiting participant when a conference sets no waitUrl
  DEFAULT_WAIT_URL = 'https://s3.amazonaws.com/com.twilio.sounds.music/index.xml'.freeze

  pattr_initialize [:inbox!, { from: '' }]

  def reject
    Twilio::TwiML::VoiceResponse.new(&:reject).to_s
  end

  def hangup
    Twilio::TwiML::VoiceResponse.new(&:hangup).to_s
  end

  # Told to the caller in place of the conference, before the call ends
  def announcement(kind)
    Twilio::TwiML::VoiceResponse.new do |response|
      Voice::CallAnnouncement.new(inbox, kind).speak(response)
      response.hangup
    end.to_s
  end

  def conference(call)
    conference_sid = Voice::Provider::Twilio::ConferenceService.new(call: call).ensure_conference_sid

    Twilio::TwiML::VoiceResponse.new.tap do |response|
      response.dial do |dial|
        dial.conference(
          conference_sid,
          start_conference_on_enter: agent_leg?,
          end_conference_on_exit: false,
          record: call.recording_enabled? ? 'record-from-start' : 'do-not-record',
          recording_status_callback: url_helpers.twilio_voice_recording_status_url(phone: phone_digits),
          recording_status_callback_event: 'completed',
          recording_status_callback_method: 'POST',
          status_callback: url_helpers.twilio_voice_conference_status_url(phone: phone_digits),
          status_callback_event: 'start end join leave',
          status_callback_method: 'POST',
          participant_label: participant_label,
          **leg_audio_options(call)
        )
      end
    end.to_s
  end

  # What an inbound caller hears until an agent joins: the greeting once, then Twilio's own
  # playlist, which loops itself
  def wait
    Twilio::TwiML::VoiceResponse.new do |response|
      greeting.speak(response) if greeting.enabled?
      response.redirect(DEFAULT_WAIT_URL, method: 'GET')
    end.to_s
  end

  private

  def agent_leg?
    from.start_with?('client:')
  end

  def participant_label
    agent_leg? ? from.delete_prefix('client:') : 'contact'
  end

  # An inbound caller hears the inbox's greeting first when one is on; otherwise Twilio's
  # default wait applies, as on every other leg
  def leg_audio_options(call)
    return {} if agent_leg? || !call.incoming? || !greeting.enabled?

    { wait_url: url_helpers.twilio_voice_wait_url(phone: phone_digits), wait_method: 'GET' }
  end

  def greeting
    @greeting ||= Voice::CallAnnouncement.new(inbox, :greeting)
  end

  def phone_digits
    inbox.channel.phone_number.delete_prefix('+')
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end
end
