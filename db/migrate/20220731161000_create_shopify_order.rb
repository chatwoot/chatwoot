class CreateShopifyOrder < ActiveRecord::Migration[6.0]
  def change
    create_table :integrations_shopify_customer, id: :serial do |t|
      t.string  :email
      t.string  :first_name
      t.string  :last_name
      t.string  :orders_count
      t.integer :contact_id
      t.integer :account_id
      t.string  :customer_id
      t.integer :shopify_account_id
      t.timestamps
    end
  end
end
