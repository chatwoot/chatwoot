class AutoResolveConversationsJob < ApplicationJob
  queue_as :medium

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation&.auto_resolve_duration && conversation&.open?

    time_since_last_activity = Time.zone.now.to_i - conversation.last_activity_at.to_i
    time_left_to_auto_resolve = conversation.auto_resolve_duration.days.to_i - time_since_last_activity
    if time_left_to_auto_resolve.positive?
      AutoResolveConversationsJob.set(wait_until: time_left_to_auto_resolve.seconds.from_now).perform_later(conversation_id)
    else
      conversation.toggle_status
    end
  end
end
