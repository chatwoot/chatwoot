class AddCompletionReasonToConversationFollowUps < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_follow_ups, :completion_reason, :string
    add_index :conversation_follow_ups, :completion_reason
  end
end
