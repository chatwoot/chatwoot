class Voice::Provider::Twilio::RecordingAttachmentJob < ApplicationJob
  queue_as :low

  retry_on Down::Error, wait: 5.seconds, attempts: 3

  def perform(conversation_id, recording_sid, recording_url, recording_duration = nil)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    Voice::Provider::Twilio::RecordingAttachmentService.new(
      conversation: conversation,
      recording_sid: recording_sid,
      recording_url: recording_url,
      recording_duration: recording_duration
    ).perform
  end
end
