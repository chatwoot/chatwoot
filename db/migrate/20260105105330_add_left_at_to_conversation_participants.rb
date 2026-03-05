class AddLeftAtToConversationParticipants < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :conversation_participants, :left_at, :datetime
    add_index :conversation_participants, :left_at, name: 'index_conversation_participants_on_left_at', algorithm: :concurrently
  end
end
