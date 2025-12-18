class AddConversationSummaryLastGeneratedAtToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :conversation_summary_last_generated_at, :datetime
  end
end
