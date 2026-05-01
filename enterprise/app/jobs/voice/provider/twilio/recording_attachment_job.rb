class Voice::Provider::Twilio::RecordingAttachmentJob < ApplicationJob
  queue_as :low

  retry_on Down::Error, wait: 5.seconds, attempts: 3

  def perform(call_id, recording_sid, recording_url, recording_duration = nil)
    Rails.logger.info(
      "VOICE_RECORDING_ATTACHMENT_JOB start call_id=#{call_id} recording_sid=#{recording_sid} duration=#{recording_duration}"
    )

    call = Call.find_by(id: call_id)
    if call.blank?
      Rails.logger.info("VOICE_RECORDING_ATTACHMENT_JOB skip reason=call_not_found call_id=#{call_id}")
      return
    end

    Voice::Provider::Twilio::RecordingAttachmentService.new(
      call: call,
      recording_sid: recording_sid,
      recording_url: recording_url,
      recording_duration: recording_duration
    ).perform

    Rails.logger.info("VOICE_RECORDING_ATTACHMENT_JOB done call_id=#{call_id} recording_sid=#{recording_sid}")
  end
end
