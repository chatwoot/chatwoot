class AddAssignedAtToConversationParticipants < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_participants, :assigned_at, :datetime
  end
end
