class AddFullHistoryRevisionToMonitorWorkItems < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_monitor_work_items, :full_history_revision, :bigint, null: false, default: 0

    reversible do |direction|
      direction.up do
        # Preserve the full-history contract of work queued before this change.
        execute <<~SQL.squish
          UPDATE conversation_monitor_work_items
          SET full_history_revision = revision
          WHERE due_at IS NOT NULL
        SQL
      end
    end
  end
end
