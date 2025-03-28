class CreateChannelShopees < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_shopees do |t|
      t.timestamps
      t.integer :account_id, null: false
      t.string :refresh_token, null: false
      t.string :access_token, null: false
      t.datetime :expires_at, null: false
      t.integer :shop_id, null: false
      t.integer :partner_id, null: false
    end

    add_index :channel_shopees, [:account_id, :shop_id], unique: true
  end
end
