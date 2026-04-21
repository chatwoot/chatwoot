class CreateSynapseosDeals < ActiveRecord::Migration[7.1]
  def change
    create_table :synapseos_deals do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts }
      t.references :lead, null: false, foreign_key: { to_table: :synapseos_leads }
      t.references :assignee, null: true, foreign_key: { to_table: :users }

      # 0=pending, 1=won, 2=lost
      t.integer :status, null: false, default: 0
      t.decimal :amount, precision: 14, scale: 2, default: 0
      t.string :currency, default: 'BRL'
      t.jsonb :metadata, null: false, default: {}
      t.datetime :closed_at

      t.timestamps
    end

    add_index :synapseos_deals, [:account_id, :status]
    add_index :synapseos_deals, [:account_id, :closed_at]
  end
end
