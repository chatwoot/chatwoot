# Applies a flipped "Record calls" flag to calls already in progress on the inbox: browser sessions
# stop/start their recorder on the broadcast, and Twilio recordings are stopped or started to match.
class Voice::RecordingSettingChangeService
  pattr_initialize [:inbox!]

  def perform
    ActionCable.server.broadcast(
      "account_#{inbox.account_id}",
      { event: 'voice_call.recording_setting',
        data: { account_id: inbox.account_id, inbox_id: inbox.id, recording_enabled: recording_enabled? } }
    )
    apply_to_twilio_calls if inbox.channel.is_a?(Channel::TwilioSms)
  end

  private

  def recording_enabled?
    inbox.channel.recording_enabled?
  end

  # Ringing calls are reconciled by Voice::Conference::Manager once their conference starts.
  def apply_to_twilio_calls
    Call.twilio.where(inbox: inbox, status: 'in_progress').find_each do |call|
      next if recording_enabled? == (call.recording_started != false)

      service = Voice::Provider::Twilio::ConferenceService.new(call: call)
      recording_enabled? ? service.start_recording : service.stop_recording
    rescue Twilio::REST::RestError => e
      Rails.logger.warn("TWILIO_VOICE_RECORDING_TOGGLE_FAILED call=#{call.id} #{e.message}")
    end
  end
end
