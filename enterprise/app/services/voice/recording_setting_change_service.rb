# Applies a changed "Record calls" flag to calls already in progress on the inbox: browser sessions
# stop/start their recorder on the broadcast, and Twilio is told to stop the live conference recording.
class Voice::RecordingSettingChangeService
  pattr_initialize [:inbox!]

  def perform
    ActionCable.server.broadcast(
      "account_#{inbox.account_id}",
      { event: 'voice_call.recording_setting',
        data: { account_id: inbox.account_id, inbox_id: inbox.id, recording_enabled: recording_enabled? } }
    )
    stop_twilio_recordings if inbox.channel.is_a?(Channel::TwilioSms) && !recording_enabled?
  end

  private

  def recording_enabled?
    inbox.channel.recording_enabled?
  end

  # The recording callback already refuses to store audio; this stops Twilio capturing it in the first place.
  def stop_twilio_recordings
    client = inbox.channel.client
    Call.twilio.where(inbox: inbox, status: 'in_progress').find_each do |call|
      next if call.twilio_conference_sid.blank?

      client.conferences(call.twilio_conference_sid).recordings('Twilio.CURRENT').update(status: 'stopped')
    rescue Twilio::REST::RestError => e
      Rails.logger.warn("TWILIO_VOICE_STOP_RECORDING_FAILED call=#{call.id} #{e.message}")
    end
  end
end
