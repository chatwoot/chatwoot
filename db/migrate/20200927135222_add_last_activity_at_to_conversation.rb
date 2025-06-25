class AddLastActivityAtToConversation < ActiveRecord::Migration[6.0]
  def up
    add_column :conversations,
               :last_activity_at,
               :datetime,
               default: -> { 'CURRENT_TIMESTAMP' },
               index: true

    add_last_activity_at_to_conversations

    change_column_null(:conversations, :last_activity_at, false)
  end

  def down
    remove_column(:conversations, :last_activity_at)
  end

  private

  def add_last_activity_at_to_conversations
    ::Conversation.find_in_batches do |conversation_batch|
      Rails.logger.info "Migrated till #{conversation_batch.first.id}\n"
      conversation_batch.each do |conversation|
        # rubocop:disable Rails/SkipsModelValidations
        last_activity_at = if conversation.messages.last
                             conversation.messages.last.created_at
                           else
                             conversation.created_at
                           end
        conversation.update_columns(last_activity_at: last_activity_at)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
end
