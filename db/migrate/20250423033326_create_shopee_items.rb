class CreateShopeeItems < ActiveRecord::Migration[7.0]
  def change
    create_table :shopee_items do |t|
      t.timestamps
      t.bigint :shop_id, null: false
      t.string :code, null: false
      t.string :sku, null: false
      t.string :name, null: false
      t.string :status, null: false
      t.jsonb :meta, default: {}, null: false
    end

    add_index :shopee_items, :shop_id
    add_index :shopee_items, :code, unique: true
    add_index :shopee_items, :sku, unique: true
  end
end
