class AddInboxIdToConversationQueues < ActiveRecord::Migration[7.1]
  def up
    add_column :conversation_queues, :inbox_id, :bigint, null: true
    add_index :conversation_queues, :inbox_id

    execute <<~SQL
      UPDATE conversation_queues cq
      SET inbox_id = conversations.inbox_id
      FROM conversations
      WHERE cq.conversation_id = conversations.id
    SQL
  end

  def down
    remove_index :conversation_queues, :inbox_id
    remove_column :conversation_queues, :inbox_id
  end
end
