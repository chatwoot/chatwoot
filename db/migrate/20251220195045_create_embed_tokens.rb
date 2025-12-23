class CreateEmbedTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :embed_tokens do |t|
      t.string :jti, null: false, index: { unique: true }
      t.string :token_digest, null: false, index: { unique: true }
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: true, foreign_key: true
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.datetime :revoked_at, null: true
      t.datetime :last_used_at, null: true
      t.integer :usage_count, default: 0, null: false
      t.string :note

      t.timestamps
    end

    add_index :embed_tokens, [:user_id, :account_id]
    add_index :embed_tokens, :revoked_at
  end
end
