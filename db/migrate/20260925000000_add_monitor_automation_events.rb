class AddMonitorAutomationEvents < ActiveRecord::Migration[7.1]
  def change
    add_evaluation_fields
    add_work_item_fields
    create_deliveries
    add_rule_fields
  end

  private

  def add_rule_fields
    add_column :automation_rules, :monitor_id, :bigint
    add_column :automation_rules, :monitor_event_activated_at, :datetime
  end

  def add_evaluation_fields
    add_column :conversation_monitor_evaluations, :first_matched_at, :datetime
    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE conversation_monitor_evaluations
          SET first_matched_at = matched_at
          WHERE status = 'matched' AND matched_at IS NOT NULL
        SQL
      end
    end
  end

  def add_work_item_fields
    add_column :conversation_monitor_work_items, :live_activity_revision, :bigint, null: false, default: 0
    add_column :conversation_monitor_work_items, :live_activity_at, :datetime
  end

  def create_deliveries
    create_table :conversation_monitor_automation_deliveries do |t|
      t.references :account, null: false
      t.references :monitor, null: false
      t.references :automation_rule, null: false
      t.references :conversation, null: false
      t.string :status, null: false, default: 'pending'
      t.string :skip_reason
      t.datetime :claimed_at
      t.timestamps
    end
    add_index :conversation_monitor_automation_deliveries, [:automation_rule_id, :monitor_id, :conversation_id],
              unique: true, name: 'index_monitor_automation_deliveries_unique'
    add_index :conversation_monitor_automation_deliveries, [:status, :updated_at],
              name: 'index_monitor_automation_deliveries_sweep'
  end
end
