class CreateShopeeOrderItems < ActiveRecord::Migration[7.0]
  def change
    create_table :shopee_order_items do |t|
      t.timestamps
      t.integer :order_id, null: false
      t.bigint :shop_id, null: false
      t.string :code, null: false
      t.string :item_code, null: false
      t.string :item_sku, null: false
      t.string :item_name, null: false
      t.integer :price, default: 0
      t.jsonb :meta, default: {}, null: false
    end

    add_index :shopee_order_items, :order_id
    add_index :shopee_order_items, :shop_id
    add_index :shopee_order_items, [:code, :order_id], unique: true
  end
end
