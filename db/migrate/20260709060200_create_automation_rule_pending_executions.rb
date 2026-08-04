class CreateAutomationRulePendingExecutions < ActiveRecord::Migration[7.0]
  def change
    create_table :automation_rule_pending_executions do |t|
      t.references :automation_rule, null: false
      t.references :conversation, null: false
      t.references :account, null: false
      t.bigint :message_id
      t.datetime :due_at, null: false
      t.string :episode_key, null: false
      t.integer :status, null: false, default: 0
      t.string :skip_reason

      t.timestamps
    end

    add_index :automation_rule_pending_executions, [:status, :due_at]
    add_index :automation_rule_pending_executions,
              [:automation_rule_id, :conversation_id, :episode_key],
              unique: true, name: 'uniq_automation_pending_execution_episode'
  end
end
