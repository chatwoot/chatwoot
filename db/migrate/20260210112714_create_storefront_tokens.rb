class CreateStorefrontTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :storefront_tokens do |t|
      t.string :token, null: false
      t.references :account, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.datetime :expires_at
      t.datetime :last_used_at
      t.timestamps
    end

    add_index :storefront_tokens, :token, unique: true
    add_index :storefront_tokens, [:account_id, :contact_id]
  end
end
