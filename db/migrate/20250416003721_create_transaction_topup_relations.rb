class CreateTransactionTopupRelations < ActiveRecord::Migration[7.0]
  def change
    create_table :transaction_topup_relations do |t|
      t.references :transaction, null: false, foreign_key: { on_delete: :cascade }, type: :bigint
      t.references :topup, null: false, foreign_key: { to_table: :subscription_topups, on_delete: :cascade }, type: :bigint
      t.timestamps

      t.index [:transaction_id, :topup_id], unique: true, name: 'index_tx_topup_rel'
    end
  end
end
