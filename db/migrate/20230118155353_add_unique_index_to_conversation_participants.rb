class AddUniqueIndexToConversationParticipants < ActiveRecord::Migration[6.1]
  def change
    add_index :conversation_participants, [:user_id, :conversation_id], unique: true
  end
end
