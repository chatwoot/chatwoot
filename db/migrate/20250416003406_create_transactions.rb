class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.string :transaction_id, null: false
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.references :account, null: false, foreign_key: true, type: :bigint
      t.string :package_type, null: false
      t.string :package_name
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :duration
      t.string :duration_unit
      t.string :status, null: false
      t.string :payment_method
      t.string :payment_url
      t.timestamp :transaction_date, default: -> { 'CURRENT_TIMESTAMP' }
      t.timestamp :payment_date
      t.timestamp :expiry_date
      t.string :action, default: 'pay'
      t.text :notes
      t.jsonb :metadata
      t.timestamps

      t.index :transaction_id, unique: true
      t.index :status
      t.index :transaction_date
      t.index :package_type
    end
  end
end
