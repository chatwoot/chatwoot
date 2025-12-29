class AddCompletedAtToConversationFollowUps < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_follow_ups, :completed_at, :datetime
    add_index :conversation_follow_ups, :completed_at
  end
end
