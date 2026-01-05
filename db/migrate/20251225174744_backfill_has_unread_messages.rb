class BackfillHasUnreadMessages < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Backfill using raw SQL for performance
    # A conversation has unread messages if there's at least one incoming, non-private message
    # created after agent_last_seen_at (or any incoming message if agent_last_seen_at is null)
    # Status: 0 = open, 3 = pending
    # Message type: 0 = incoming
    execute <<~SQL
      UPDATE conversations
      SET has_unread_messages = true
      WHERE id IN (
        SELECT DISTINCT c.id
        FROM conversations c
        INNER JOIN messages m ON m.conversation_id = c.id
        WHERE c.status IN (0, 3)
          AND m.message_type = 0
          AND m.private = false
          AND (
            c.agent_last_seen_at IS NULL
            OR m.created_at > c.agent_last_seen_at
          )
      )
    SQL
  end

  def down
    execute <<~SQL
      UPDATE conversations SET has_unread_messages = false
    SQL
  end
end
