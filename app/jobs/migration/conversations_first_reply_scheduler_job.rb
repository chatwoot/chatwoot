# Delete migration and spec after 2 consecutive releases.
class Migration::ConversationsFirstReplySchedulerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform(account)
    account.conversations.each do |conversation|
      # rubocop:disable Rails/SkipsModelValidations
      if conversation.messages.outgoing.where("(additional_attributes->'campaign_id') is null").count.positive?
        conversation.update_columns(first_reply_created_at: conversation.messages.outgoing.where("(additional_attributes->'campaign_id') is null")
        .first.created_at)
      else
        conversation.update_columns(first_reply_created_at: nil)
      end
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
