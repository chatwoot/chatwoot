class CreateTransactionSubscriptionRelations < ActiveRecord::Migration[7.0]
  def change
    create_table :transaction_subscription_relations do |t|
      t.references :transaction, null: false, foreign_key: { on_delete: :cascade }, type: :bigint
      t.references :subscription, null: false, foreign_key: { on_delete: :cascade }, type: :bigint
      t.timestamps

      t.index [:transaction_id, :subscription_id], unique: true, name: 'index_tx_sub_rel'
    end
  end
end
