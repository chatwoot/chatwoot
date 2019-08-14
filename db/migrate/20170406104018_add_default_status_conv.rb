class AddDefaultStatusConv < ActiveRecord::Migration[5.0]
  def change
    change_column :conversations, :status, :integer, null: false, default: 0
    change_column :conversations, :inbox_id, :integer, null: false
    change_column :conversations, :account_id, :integer, null: false
    change_column :contacts, :inbox_id, :integer, null: false
    change_column :contacts, :account_id, :integer, null: false
    change_column :canned_responses, :account_id, :integer, null: false
    change_column :inbox_members, :user_id, :integer, null: false
    change_column :inbox_members, :inbox_id, :integer, null: false
    change_column :inboxes, :channel_id, :integer, null: false
    change_column :inboxes, :account_id, :integer, null: false
    change_column :inboxes, :name, :string, null: false
    change_column :messages, :account_id, :integer, null: false
    change_column :messages, :inbox_id, :integer, null: false
    change_column :messages, :conversation_id, :integer, null: false
    change_column :messages, :message_type, :integer, null: false
    change_column :facebook_pages, :name, :string, null: false
  end
end
