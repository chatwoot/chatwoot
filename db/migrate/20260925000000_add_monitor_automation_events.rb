class AddMonitorAutomationEvents < ActiveRecord::Migration[7.1]
  def change
    add_rule_fields
    add_evaluation_fields
    add_work_item_fields
    create_deliveries
  end

  private

  def add_rule_fields
    add_reference :automation_rules, :monitor, foreign_key: { to_table: :conversation_monitors, on_delete: :nullify }
    add_column :automation_rules, :monitor_name, :string
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
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :monitor, null: false, foreign_key: { to_table: :conversation_monitors, on_delete: :cascade }
      t.references :automation_rule, null: false, foreign_key: { on_delete: :cascade }
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
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
