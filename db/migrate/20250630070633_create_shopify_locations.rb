class CreateShopifyLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :shopify_locations do |t|
      t.string  :name, null: false
      t.boolean :ships_inventory, default: false, null: false
      t.boolean :fulfills_online_orders, default: false, null: false
      t.boolean :is_active, default: true, null: false

      t.jsonb   :address, null: false, default: {}

      t.timestamps
      t.references :account, foreign_key: true, index: true, null: true
    end
  end
end