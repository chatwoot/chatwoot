class AddIndexOnFbPage < ActiveRecord::Migration[5.0]
  def change
    add_index :facebook_pages, :page_id
    add_index :conversations, :account_id
    add_index :contacts, :account_id
    add_index :inbox_members, :inbox_id
    add_index :inboxes, :account_id
    add_index :messages, :conversation_id
  end
end
