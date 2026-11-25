class AddReopenOwnerToInboxes < ActiveRecord::Migration[7.2]
  def change
    add_column :inboxes, :reopen_owner, :integer, default: 0, null: false
    add_column :inboxes, :reopen_owner_window_hours, :integer
  end
end
