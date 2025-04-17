class CreateSubscriptionTopups < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_topups do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :topup_type, null: false
      t.integer :amount, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :status, null: false
      t.string :duitku_transaction_id
      t.string :duitku_order_id
      t.string :payment_method
      t.string :payment_url
      t.timestamp :paid_at
      t.timestamp :expires_at

      t.timestamps
    end
  end
end
