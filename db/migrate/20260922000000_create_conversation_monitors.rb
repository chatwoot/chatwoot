class CreateConversationMonitors < ActiveRecord::Migration[7.1]
  def change
    create_monitors
    create_evaluations
    create_scans
    create_work_items
    create_daily_usages
  end

  private

  def create_monitors
    create_table :conversation_monitors do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :name, null: false
      t.text :condition, null: false
      t.string :model, null: false
      t.float :threshold, null: false
      t.datetime :history_since, null: false
      t.datetime :paused_at
      t.datetime :resumed_at
      t.datetime :deleted_at
      t.bigint :data_revision, null: false, default: 0
      t.bigint :collection_version, null: false, default: 0
      t.datetime :recheck_requested_at
      t.timestamps
    end
  end

  def create_evaluations
    create_table :conversation_monitor_evaluations do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :monitor, null: false, foreign_key: { to_table: :conversation_monitors, on_delete: :cascade }
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.string :status, null: false, default: 'pending'
      t.bigint :input_revision, null: false, default: 0
      t.bigint :generation, null: false, default: 0
      t.bigint :requested_version
      t.float :score
      t.string :model
      t.string :error_code
      t.datetime :matched_at
      t.datetime :evaluated_at
      t.timestamps
    end
    add_index :conversation_monitor_evaluations, [:monitor_id, :conversation_id], unique: true, name: 'index_monitor_evaluations_unique'
    add_index :conversation_monitor_evaluations, [:monitor_id, :status, :conversation_id], name: 'index_monitor_evaluations_status'
  end

  def create_scans
    create_table :conversation_monitor_scans do |t|
      t.references :monitor, null: false, foreign_key: { to_table: :conversation_monitors, on_delete: :cascade }, index: false
      t.string :kind, null: false
      t.bigint :collection_version, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: false
      t.bigint :cursor, null: false, default: 0
      t.datetime :enumerated_at
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :conversation_monitor_scans, [:monitor_id, :collection_version, :kind], unique: true, name: 'index_monitor_scans_version_kind'
    add_index :conversation_monitor_scans, :monitor_id, unique: true, where: "kind = 'initial'", name: 'index_monitor_scans_initial'
  end

  def create_work_items
    create_table :conversation_monitor_work_items do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.bigint :revision, null: false, default: 0
      t.bigint :processed_revision, null: false, default: 0
      t.bigint :full_history_revision, null: false, default: 0
      t.bigint :generation, null: false, default: 0
      t.datetime :due_at
      t.string :lease_token
      t.datetime :lease_expires_at
      t.integer :attempts, null: false, default: 0
      t.string :error_code
      t.datetime :requested_at
      t.datetime :activity_at
      t.timestamps
    end
    add_index :conversation_monitor_work_items, :due_at, where: 'due_at IS NOT NULL', name: 'index_monitor_work_due'
  end

  def create_daily_usages
    create_table :conversation_monitor_daily_usages do |t|
      t.references :account, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.date :usage_date, null: false
      t.integer :calls_count, null: false, default: 0
      t.datetime :limit_reached_at
      t.timestamps
    end

    add_index :conversation_monitor_daily_usages, [:account_id, :usage_date], unique: true, name: 'index_monitor_daily_usage_unique'
    add_check_constraint :conversation_monitor_daily_usages, 'calls_count >= 0', name: 'monitor_daily_usage_nonnegative'
  end
end
