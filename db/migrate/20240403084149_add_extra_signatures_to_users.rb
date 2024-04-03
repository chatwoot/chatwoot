class AddExtraSignaturesToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :azar_message_signature, :text
    add_column :users, :mono_message_signature, :text
    add_column :users, :gbits_message_signature, :text
  end
end
