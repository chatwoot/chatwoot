module ConversationMonitors::AttachmentTracking
  extend ActiveSupport::Concern

  included do
    after_update :request_transcript_evaluation, if: :monitor_transcript_changed?
    after_update_commit :wake_transcript_evaluation
  end

  private

  def monitor_transcript_changed?
    audio? && saved_change_to_meta? && meta&.dig('transcribed_text').present? &&
      meta_before_last_save&.dig('transcribed_text') != meta['transcribed_text']
  end

  def request_transcript_evaluation
    return unless (message.incoming? || message.outgoing?) && !message.private?
    return if message.content.present? || message.content_attributes['deleted']

    @monitor_transcript_work = ConversationMonitors::Scheduler.request(message.conversation, full_history: true)
  end

  def wake_transcript_evaluation
    return unless @monitor_transcript_work

    @monitor_transcript_work = nil
    ConversationMonitors::Scheduler.wake(message.conversation_id)
  end
end
