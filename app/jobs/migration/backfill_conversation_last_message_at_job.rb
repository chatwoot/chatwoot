class Migration::BackfillConversationLastMessageAtJob < ApplicationJob
  queue_as :async_database_migration

  BATCH_SIZE = 1000

  def perform(after_id = 0)
    ids = Conversation.where('id > ?', after_id).order(:id).limit(BATCH_SIZE).pluck(:id)
    return if ids.empty?

    latest_message = Message.chat.where('messages.conversation_id = conversations.id AND messages.account_id = conversations.account_id')
                            .reorder(created_at: :desc).limit(1).select(:created_at)
    # Preserve messages received while the backfill is running. Do not emit activity or touch updated_at.
    Conversation.where(id: ids).update_all( # rubocop:disable Rails/SkipsModelValidations
      "last_message_at = GREATEST(last_message_at, (#{latest_message.to_sql}))"
    )
    self.class.perform_later(ids.last) if ids.size == BATCH_SIZE
  end
end
