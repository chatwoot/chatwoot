class ChangeScheduledMessagesAuthorToNullable < ActiveRecord::Migration[7.1]
  def up
    change_column_null :scheduled_messages, :author_id, true
    change_column_null :scheduled_messages, :author_type, true
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Can't revert because there might be scheduled messages with null author_id/author_type"
  end
end
