class AddIndexToMessageAttachments < ActiveRecord::Migration[6.1]
  def change
    add_index :attachments, :account_id
    add_index :attachments, :message_id
    add_index :conversations, :contact_id
    add_index :conversations, :inbox_id
  end
end
