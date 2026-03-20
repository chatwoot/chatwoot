class AddIsActiveIndexToConversationGroupMembers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :conversation_group_members, [:conversation_id, :is_active],
              algorithm: :concurrently
  end
end
