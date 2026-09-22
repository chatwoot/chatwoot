class AddConversationMonitorResumptions < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_monitors, :collection_version, :bigint, null: false, default: 0
    add_column :conversation_monitors, :resumed_at, :datetime
    add_column :conversation_monitor_work_items, :activity_at, :datetime
    add_column :conversation_monitor_evaluations, :requested_version, :bigint
    add_column :conversation_monitor_backfills, :cancelled_at, :datetime

    create_table :conversation_monitor_resumptions do |t|
      t.references :monitor, null: false, foreign_key: { to_table: :conversation_monitors, on_delete: :cascade }
      t.bigint :collection_version, null: false
      t.string :mode, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: false
      t.bigint :cursor, null: false, default: 0
      t.datetime :enumerated_at
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :conversation_monitor_resumptions, [:monitor_id, :collection_version], unique: true, name: 'index_monitor_resumptions_version'
  end
end
