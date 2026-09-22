class LowerConversationMonitorThreshold < ActiveRecord::Migration[7.1]
  def up
    # Reuse saved scores when lowering the original default. Pending, skipped,
    # failed, and already-matched evaluations retain their existing state.
    execute <<~SQL.squish
      WITH updated_monitors AS (
        UPDATE conversation_monitors
        SET threshold = 0.6, data_revision = data_revision + 1, updated_at = CURRENT_TIMESTAMP
        WHERE threshold = 0.65
        RETURNING id
      )
      UPDATE conversation_monitor_evaluations AS evaluations
      SET status = 'matched', matched_at = evaluations.evaluated_at, updated_at = CURRENT_TIMESTAMP
      FROM updated_monitors
      WHERE evaluations.monitor_id = updated_monitors.id
        AND evaluations.status = 'unmatched'
        AND evaluations.score >= 0.6
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Restoring the previous threshold would remove accepted monitor memberships'
  end
end
