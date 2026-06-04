class AddGroupSessionAdminToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :group_session_admin, :boolean, default: false, null: false
  end
end
