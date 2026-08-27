class Voice::RecordingStatusService
  pattr_initialize [:account!, { payload: {} }]

  def perform
    return unless completed_recording?
    return if recording_sid.blank? || recording_url.blank?

    call = find_call
    return if call.blank? || Array(call.discarded_recording_sids).include?(recording_sid)

    Voice::Provider::Twilio::RecordingAttachmentJob.perform_later(
      call.id,
      recording_sid,
      recording_url,
      recording_duration
    )
  end

  private

  # Conference recordings carry ConferenceSid; recordings started on the contact leg mid-call carry only CallSid.
  def find_call
    calls = Call.where(account_id: account.id)
    return calls.by_twilio_conference_sid(conference_sid).first if conference_sid.present?

    calls.find_by(provider: :twilio, provider_call_id: payload['CallSid'].to_s.presence)
  end

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
