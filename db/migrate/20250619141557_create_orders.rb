class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.string   :name # Shopify order number (e.g., "#1001")
      t.integer  :customer_id

      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.jsonb    :line_items, default: [], null: false # Array of line items
      t.jsonb    :shipping_address # Shipping address details
      t.jsonb    :billing_address  # Billing address details
      t.jsonb    :shipping_lines, default: [], null: false # Array of shipping lines

      t.decimal  :subtotal_price, precision: 15, scale: 2
      t.decimal  :total_price, precision: 15, scale: 2
      t.decimal  :total_tax, precision: 15, scale: 2
      t.string   :currency

      t.string   :financial_status
      t.string   :fulfillment_status

      t.string   :order_status_url

      t.string   :tags
      t.text     :note

      t.jsonb    :refunds, default: [], null: false

      t.string   :cancel_reason
      t.datetime :cancelled_at

      t.index :customer_id
      t.index :name
      t.index :created_at
      t.references :account, foreign_key: true, index: true, null: true
    end
  end
end
