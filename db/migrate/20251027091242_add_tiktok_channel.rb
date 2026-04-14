class AddTiktokChannel < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_tiktok do |t|
      t.integer :account_id, null: false
      t.string :business_id, null: false
      t.string :access_token, null: false
      t.datetime :expires_at, null: false
      t.string :refresh_token, null: false
      t.datetime :refresh_token_expires_at, null: false
      t.timestamps
    end

    add_index :channel_tiktok, :business_id, unique: true
  end
end
