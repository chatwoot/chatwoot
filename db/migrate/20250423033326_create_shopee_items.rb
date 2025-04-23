class CreateShopeeItems < ActiveRecord::Migration[7.0]
  def change
    create_table :shopee_items do |t|
      t.timestamps
      t.string :code, null: false
      t.string :sku, null: false
      t.string :name, null: false
      t.string :status, null: false
    end

    add_index :shopee_items, :code, unique: true
    add_index :shopee_items, :sku, unique: true
  end
end
