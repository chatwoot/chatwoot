class CreatePaymentLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_links do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :message, null: false, foreign_key: true, index: { unique: true }
      t.references :contact, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.string :payment_id, null: false
      t.string :payment_url, null: false
      t.string :track_id, null: false

      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false, default: 'KWD'

      t.integer :status, default: 0, null: false
      t.datetime :paid_at
      t.datetime :expires_at

      t.jsonb :customer_data, default: {}

      t.timestamps
    end

    add_index :payment_links, :payment_id, unique: true
    add_index :payment_links, :status
  end
end
