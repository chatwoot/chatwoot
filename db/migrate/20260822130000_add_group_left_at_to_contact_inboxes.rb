class AddGroupLeftAtToContactInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :contact_inboxes, :group_left_at, :datetime
  end
end
