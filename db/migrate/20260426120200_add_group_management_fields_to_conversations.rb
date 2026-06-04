class AddGroupManagementFieldsToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :group_description, :text
    add_column :conversations, :group_invite_link, :string
    add_column :conversations, :group_join_approval_mode, :string
    add_column :conversations, :group_suspended, :boolean, default: false, null: false
    add_column :conversations, :group_created_at_external, :datetime
    add_column :conversations, :group_contacts_synced_at, :datetime
  end
end
