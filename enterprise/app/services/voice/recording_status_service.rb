class Voice::RecordingStatusService
  pattr_initialize [:account!, { payload: {} }]

  def perform
    return unless completed_recording?
    return if conference_sid.blank? || recording_sid.blank? || recording_url.blank?

    call = Call.where(account_id: account.id).by_twilio_conference_sid(conference_sid).first
    return if call.blank?

    # This call's TwiML asked Twilio not to record, so drop anything it still reports.
    if call.recording_enabled == false
      Rails.logger.warn("TWILIO_VOICE_RECORDING_DISCARDED call_id=#{call.id} recording_sid=#{recording_sid}")
      return
    end

    Voice::Provider::Twilio::RecordingAttachmentJob.perform_later(
      call.id,
      recording_sid,
      recording_url,
      recording_duration
    )
  end

  private

  def completed_recording?
    payload['RecordingStatus'].to_s.casecmp('completed').zero?
  end

  def conference_sid
    payload['ConferenceSid'].to_s
  end

  def recording_sid
    payload['RecordingSid'].to_s
  end

  def recording_url
    payload['RecordingUrl'].to_s
  end

  def recording_duration
    payload['RecordingDuration']
  end
end
