class Voice::StatusUpdateService
  pattr_initialize [:account!, :call_sid!, :call_status]

  def perform
    Rails.logger.info(
      "VOICE_STATUS_UPDATE account=#{account.id} call_sid=#{call_sid} status=#{call_status}"
    )
    conversation = account.conversations.find_by(identifier: call_sid)
    return unless conversation
    return if call_status.to_s.strip.empty?

    Voice::CallStatus::Manager.new(
      conversation: conversation,
      call_sid: call_sid,
      provider: :twilio
    ).process_status_update(call_status)
    Rails.logger.info(
      "VOICE_STATUS_UPDATED account=#{account.id} conversation=#{conversation.display_id} status=#{call_status}"
    )
  end
end
