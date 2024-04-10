class AddPubSubTokenToContactInbox < ActiveRecord::Migration[6.1]
  def change
    add_column :contact_inboxes, :pubsub_token, :string
    add_index :contact_inboxes, :pubsub_token, unique: true
  end
end
