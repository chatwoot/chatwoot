class Conversations::UnassignConversationJob < ApplicationJob
  queue_as :default

  def perform(user, account)
    # rubocop:disable Rails/SkipsModelValidations
    user.assigned_conversations.where(account: account).in_batches.update_all(assignee_id: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
