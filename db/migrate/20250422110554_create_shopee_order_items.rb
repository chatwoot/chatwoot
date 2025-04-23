class CreateShopeeOrderItems < ActiveRecord::Migration[7.0]
  def change
    create_table :shopee_order_items do |t|
      t.timestamps
      t.integer :order_id, null: false
      t.bigint :item_id, null: false
      t.string :item_name
      t.string :item_sku
      t.boolean :main_item
      t.integer :model_quantity_purchased
      t.float :model_original_price
      t.float :model_discounted_price
      t.text :meta_data
    end

    add_index :shopee_order_items, :order_id
  end
end
