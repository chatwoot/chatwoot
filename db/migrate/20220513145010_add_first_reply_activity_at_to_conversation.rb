class AddFirstReplyActivityAtToConversation < ActiveRecord::Migration[6.1]
  def change
    add_column :conversations, :first_reply_created_at, :datetime
    add_index :conversations, :first_reply_created_at

    # rubocop:disable Rails/SkipsModelValidations
    ::Conversation.update_all(first_reply_created_at: Time.now.utc)
    # rubocop:enable Rails/SkipsModelValidations

    backfill_first_reply_activity_at_to_conversations
  end

  private

  def backfill_first_reply_activity_at_to_conversations
    ::Account.find_in_batches do |account_batch|
      Rails.logger.info "Migrated till #{account_batch.first.id}\n"
      account_batch.each do |account|
        Migration::ConversationsFirstReplySchedulerJob.perform_later(account)
      end
    end
  end
end
