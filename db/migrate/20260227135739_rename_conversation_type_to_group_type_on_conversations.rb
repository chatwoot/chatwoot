class RenameConversationTypeToGroupTypeOnConversations < ActiveRecord::Migration[7.1]
  def up
    rename_column :conversations, :conversation_type, :group_type

    execute <<-SQL.squish
      ALTER INDEX IF EXISTS index_conversations_on_account_id_and_conversation_type
      RENAME TO index_conversations_on_account_id_and_group_type;
    SQL

    execute <<-SQL.squish
      ALTER INDEX IF EXISTS index_conversations_on_inbox_id_and_conversation_type
      RENAME TO index_conversations_on_inbox_id_and_group_type;
    SQL
  end

  def down
    rename_column :conversations, :group_type, :conversation_type

    execute <<-SQL.squish
      ALTER INDEX IF EXISTS index_conversations_on_account_id_and_group_type
      RENAME TO index_conversations_on_account_id_and_conversation_type;
    SQL

    execute <<-SQL.squish
      ALTER INDEX IF EXISTS index_conversations_on_inbox_id_and_group_type
      RENAME TO index_conversations_on_inbox_id_and_conversation_type;
    SQL
  end
end
