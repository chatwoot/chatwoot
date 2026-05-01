class Voice::RecordingStatusService
  pattr_initialize [:account!, { payload: {} }]

  def perform # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    Rails.logger.info(
      "VOICE_RECORDING_STATUS_SERVICE account=#{account.id} status=#{payload['RecordingStatus']} " \
      "conference_sid=#{conference_sid} recording_sid=#{recording_sid}"
    )

    unless completed_recording?
      Rails.logger.info("VOICE_RECORDING_STATUS_SERVICE skip reason=not_completed status=#{payload['RecordingStatus']}")
      return
    end

    if conference_sid.blank? || recording_sid.blank? || recording_url.blank?
      Rails.logger.info(
        'VOICE_RECORDING_STATUS_SERVICE skip reason=missing_payload ' \
        "conference_sid=#{conference_sid.present?} recording_sid=#{recording_sid.present?} recording_url=#{recording_url.present?}"
      )
      return
    end

    call = Call.where(account_id: account.id).by_conference_sid(conference_sid).first
    if call.blank?
      Rails.logger.info(
        "VOICE_RECORDING_STATUS_SERVICE skip reason=call_not_found account=#{account.id} conference_sid=#{conference_sid}"
      )
      return
    end

    Rails.logger.info(
      "VOICE_RECORDING_STATUS_SERVICE enqueue call_id=#{call.id} recording_sid=#{recording_sid} duration=#{recording_duration}"
    )
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
