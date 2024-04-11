# Delete migration and spec after 2 consecutive releases.
class Migration::ConversationsFirstReplySchedulerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    conversations = Conversation.where(first_reply_created_at: nil)
    conversations.each do |conversation|
      # rubocop:disable Rails/SkipsModelValidations
      outgoing_messages = conversation.messages.outgoing.where(private: false).where("(additional_attributes->'campaign_id') is null")
      first_reply_created_at = outgoing_messages.first&.created_at
      conversation.update_columns(first_reply_created_at: first_reply_created_at) if first_reply_created_at.present?
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
