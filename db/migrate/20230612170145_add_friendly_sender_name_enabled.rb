class AddFriendlySenderNameEnabled < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :friendly_sender_name_enabled, :boolean, default: false
  end
end
