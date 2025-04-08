class CreateSubscriptionPayment < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_payments do |t|
      t.references :subscription, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :duitku_transaction_id
      t.string :duitku_order_id, null: false
      t.string :payment_method
      t.string :payment_url
      t.string :status, default: 'pending', null: false
      t.datetime :paid_at
      t.datetime :expires_at
      t.text :payment_details
      t.timestamps
    end
    add_index :subscription_payments, :duitku_order_id
  end
end
