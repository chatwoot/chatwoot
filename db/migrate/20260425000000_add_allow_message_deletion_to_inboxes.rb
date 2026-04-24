class AddAllowMessageDeletionToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :allow_message_deletion, :boolean, default: true, null: false
  end
end
