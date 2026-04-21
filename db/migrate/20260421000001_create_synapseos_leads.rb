class CreateSynapseosLeads < ActiveRecord::Migration[7.1]
  def change
    create_table :synapseos_leads do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts }
      t.references :conversation, null: false, foreign_key: { to_table: :conversations }
      t.references :contact, null: true, foreign_key: { to_table: :contacts }
      t.references :assignee, null: true, foreign_key: { to_table: :users }

      # 0=open, 1=qualified, 2=disqualified, 3=converted
      t.integer :status, null: false, default: 0
      t.string :source
      t.jsonb :metadata, null: false, default: {}
      t.datetime :qualified_at
      t.datetime :disqualified_at

      t.timestamps
    end

    add_index :synapseos_leads, [:account_id, :status]
    add_index :synapseos_leads, [:account_id, :created_at]
    add_index :synapseos_leads, [:account_id, :conversation_id], unique: true
  end
end
