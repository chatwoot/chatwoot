class CreatePaymentLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_links do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :message, null: true, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.string :external_payment_id
      t.string :payment_url, null: true
      t.string :provider, null: false, default: nil

      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false, default: nil

      t.integer :status, default: 0, null: false
      t.jsonb :payload, default: {}, null: false

      t.timestamps
    end

    add_index :payment_links, :external_payment_id, unique: true
    add_index :payment_links, :status
    add_index :payment_links, :provider
  end
end
