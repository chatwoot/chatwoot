class CreateShopeeOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :shopee_orders do |t|
      t.timestamps
      t.bigint :shop_id, null: false
      t.string :number, null: false
      t.string :buyer_user_id
      t.string :buyer_username
      t.string :status
      t.integer :total_amount
      t.boolean :cod
      t.jsonb :meta, default: {}
    end

    add_index :shopee_orders, :number, unique: true
    add_index :shopee_orders, :shop_id
    add_index :shopee_orders, :buyer_user_id
    add_index :shopee_orders, :buyer_username
    add_index :shopee_orders, :status
  end
end
