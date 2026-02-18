class CreateCrmFlowExecutions < ActiveRecord::Migration[7.0]
  def change
    create_table :crm_flow_executions do |t|
      t.references :crm_flow, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :contact, foreign_key: true
      t.string :trigger_type
      t.string :status, null: false, default: 'pending'
      t.jsonb :results, default: []
      t.jsonb :metadata, default: {}
      t.string :idempotency_key

      t.timestamps
    end

    add_index :crm_flow_executions, :idempotency_key, unique: true
    add_index :crm_flow_executions, [:crm_flow_id, :conversation_id]
    add_index :crm_flow_executions, [:conversation_id, :created_at]
  end
end
