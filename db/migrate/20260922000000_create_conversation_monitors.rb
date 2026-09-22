class CreateConversationMonitors < ActiveRecord::Migration[7.1]
  def change
    create_monitors
    create_evaluations
    create_backfills
    create_work_items
  end

  private

  def create_monitors
    create_table :conversation_monitors do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :creator, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :name, null: false
      t.text :condition, null: false
      t.string :model, null: false
      t.float :threshold, null: false
      t.integer :context_version, null: false, default: 1
      t.datetime :history_since, null: false
      t.datetime :archived_at
      t.datetime :deleted_at
      t.bigint :data_revision, null: false, default: 0
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

  def create_backfills
    create_table :conversation_monitor_backfills do |t|
      t.references :monitor, null: false, foreign_key: { to_table: :conversation_monitors, on_delete: :cascade }, index: { unique: true }
      t.bigint :cursor, null: false, default: 0
      t.datetime :enumerated_at
      t.timestamps
    end
  end

  def create_work_items
    create_table :conversation_monitor_work_items do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.bigint :revision, null: false, default: 0
      t.bigint :processed_revision, null: false, default: 0
      t.bigint :generation, null: false, default: 0
      t.datetime :due_at
      t.string :lease_token
      t.datetime :lease_expires_at
      t.integer :attempts, null: false, default: 0
      t.string :error_code
      t.datetime :requested_at
      t.timestamps
    end
    add_index :conversation_monitor_work_items, :due_at, where: 'due_at IS NOT NULL', name: 'index_monitor_work_due'
  end
end
