class CreateShopifyCustomApps < ActiveRecord::Migration[7.1]
  def change
    create_table :shopify_custom_apps do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :shop_domain, null: false
      t.string :client_id, null: false
      t.text :client_secret, null: false
      t.text :install_url, null: false
      t.boolean :enabled, null: false, default: true
      t.integer :installation_generation, null: false, default: 0
      t.timestamps
    end
    add_index :shopify_custom_apps, :shop_domain, unique: true
    add_index :shopify_custom_apps, :client_id, unique: true
  end
end
