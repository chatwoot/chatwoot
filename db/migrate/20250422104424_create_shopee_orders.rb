class CreateShopeeOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :shopee_orders do |t|
      t.timestamps
      t.string :number, null: false
      t.string :status
      t.boolean :cod
      t.integer :total_amount
      t.string :shipping_carrier
      t.string :payment_method
      t.integer :estimated_shipping_fee
      t.string :message_to_seller
      t.datetime :create_time
      t.integer :days_to_ship
      t.string :note
      t.integer :actual_shipping_fee
      t.text :recipient_address
      t.datetime :pay_time
      t.string :cancel_reason
      t.string :cancel_by
      t.string :buyer_cancel_reason
      t.datetime :pickup_done_time
      t.string :booking_sn
    end

    add_index :shopee_orders, :number, unique: true
  end
end
