class CreateShopifyOrder < ActiveRecord::Migration[6.0]
  def change
    create_table :integrations_shopify_order, id: :serial do |t|
      t.string  :order_id
      t.string  :cancelled_at
      t.string  :closed_at
      t.string  :currency
      t.string  :current_total_price
      t.string  :order_number
      t.string  :order_status_url
      t.string  :order_created_at
      t.integer :customer_id
      t.integer :account_id
      t.timestamps
    end
    create_table :integrations_shopify_customer, id: :serial do |t|
      t.string  :email
      t.string  :first_name
      t.string  :last_name
      t.string  :orders_count
      t.integer :contact_id
      t.integer :account_id
      t.timestamps
    end
    create_table :integrations_shopify_order_item, id: :serial do |t|
      t.integer :order_id
      t.string  :name
      t.string  :price
      t.string  :quantity
      t.timestamps
    end
  end
end
