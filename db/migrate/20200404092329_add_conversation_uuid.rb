class AddConversationUuid < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto'
    add_column :conversations, :uuid, :uuid, default: 'gen_random_uuid()', null: false
  end
end
