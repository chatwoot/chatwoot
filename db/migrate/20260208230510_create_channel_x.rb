class CreateChannelX < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_x do |t|
      t.bigint :account_id, null: false
      t.string :profile_id, null: false
      t.string :username, null: false
      t.string :name
      t.string :profile_image_url

      # OAuth 2.0 tokens
      t.string :bearer_token
      t.string :refresh_token
      t.datetime :token_expires_at
      t.datetime :refresh_token_expires_at

      # Reauthorization tracking
      t.integer :authorization_error_count, default: 0

      # Webhook configuration
      t.string :webhook_id

      t.timestamps
    end

    add_index :channel_x, [:profile_id], unique: true
    add_index :channel_x, [:account_id]
    add_foreign_key :channel_x, :accounts, on_delete: :cascade
  end
end
