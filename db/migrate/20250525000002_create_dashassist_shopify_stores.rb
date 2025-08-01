class CreateDashassistShopifyStores < ActiveRecord::Migration[7.0]
  def change
    create_table :dashassist_shopify_stores do |t|
      t.string :shop, null: false
      t.references :inbox, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.boolean :enabled, default: true, null: false
      t.timestamps
    end

    add_index :dashassist_shopify_stores, :shop, unique: true
  end
end 