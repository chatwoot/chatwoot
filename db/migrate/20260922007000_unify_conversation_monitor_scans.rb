class UnifyConversationMonitorScans < ActiveRecord::Migration[7.1]
  def up
    create_scans
    copy_scans
    execute 'UPDATE conversation_monitors SET paused_at = COALESCE(paused_at, archived_at) WHERE archived_at IS NOT NULL'
    drop_table :conversation_monitor_backfills
    drop_table :conversation_monitor_resumptions
    remove_column :conversation_monitors, :archived_at
    remove_column :conversation_monitors, :context_version
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Historical scan identities and archive state have been consolidated'
  end

  private

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

  def copy_scans
    execute <<~SQL.squish
      INSERT INTO conversation_monitor_scans
        (monitor_id, kind, collection_version, started_at, ended_at, cursor, enumerated_at, cancelled_at, created_at, updated_at)
      SELECT backfills.monitor_id, 'initial', monitors.collection_version, monitors.history_since, monitors.created_at,
             backfills.cursor, backfills.enumerated_at, backfills.cancelled_at, backfills.created_at, backfills.updated_at
      FROM conversation_monitor_backfills AS backfills
      JOIN conversation_monitors AS monitors ON monitors.id = backfills.monitor_id
    SQL
    execute <<~SQL.squish
      INSERT INTO conversation_monitor_scans
        (monitor_id, kind, collection_version, started_at, ended_at, cursor, enumerated_at, cancelled_at, created_at, updated_at)
      SELECT monitor_id, mode, collection_version, started_at, ended_at, cursor, enumerated_at, cancelled_at, created_at, updated_at
      FROM conversation_monitor_resumptions
    SQL
  end
end
