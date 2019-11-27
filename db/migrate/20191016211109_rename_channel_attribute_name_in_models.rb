class RenameChannelAttributeNameInModels < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :channel, :pubsub_token
    rename_column :contacts, :chat_channel, :pubsub_token

    add_index :users, :pubsub_token, unique: true
    add_index :contacts, :pubsub_token, unique: true
  end
end
