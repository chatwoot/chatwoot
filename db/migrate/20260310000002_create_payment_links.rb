class CreatePaymentLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_links do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :conversation, null: false, foreign_key: true, index: true
      t.references :user, foreign_key: true
      t.string :order_nsu, null: false
      t.integer :amount_cents, null: false
      t.string :description
      t.string :checkout_url
      t.string :status, default: 'pending', null: false
      t.string :invoice_slug
      t.string :transaction_nsu
      t.string :capture_method
      t.integer :paid_amount_cents
      t.string :receipt_url
      t.jsonb :webhook_payload, default: {}
      t.timestamps
    end

    add_index :payment_links, :order_nsu, unique: true
    add_index :payment_links, :status
  end
end
