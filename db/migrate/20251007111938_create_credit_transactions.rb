class CreateCreditTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :credit_transactions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :transaction_type, null: false
      t.integer :amount, null: false
      t.string :credit_type, null: false
      t.string :description
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :credit_transactions, [:account_id, :created_at]
  end
end
