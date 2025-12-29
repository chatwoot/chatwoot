class AddProcessingFieldsToConversationFollowUps < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_follow_ups, :processing_started_at, :datetime
    add_index :conversation_follow_ups, :processing_started_at
  end
end
