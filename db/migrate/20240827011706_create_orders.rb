class CreateOrders < ActiveRecord::Migration[7.0]
  def change # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    create_table :orders do |t| # rubocop:disable Metrics/BlockLength
      t.string :order_number
      t.string :order_key
      t.string :created_via
      t.string :platform
      t.string :status
      t.string :currency
      t.datetime :date_created
      t.datetime :date_created_gmt
      t.datetime :date_modified
      t.datetime :date_modified_gmt
      t.string :discount_total
      t.string :discount_tax
      t.string :shipping_total
      t.string :shipping_tax
      t.string :cart_tax
      t.string :total
      t.string :total_tax
      t.boolean :prices_include_tax, null: false, default: false
      t.integer :contact_id
      t.string :customer_ip_address
      t.string :customer_user_agent
      t.string :customer_note
      t.string :payment_method
      t.string :payment_method_title
      t.string :payment_status
      t.string :transaction_id
      t.datetime :date_paid
      t.datetime :date_paid_gmt
      t.datetime :date_completed
      t.datetime :date_completed_gmt
      t.string :cart_hash
      t.boolean :set_paid, null: false, default: false
      t.timestamps
    end
  end
end
