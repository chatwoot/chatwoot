class AddAiAssigneeTypeToConversations < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_column :conversations, :ai_assignee_type, :string unless column_exists?(:conversations, :ai_assignee_type)

    # rubocop:disable Rails/SkipsModelValidations
    Conversation.in_batches(of: 100_000, use_ranges: true) do |conversation_range|
      conversation_range.where(ai_assignee_type: nil).where.not(assignee_agent_bot_id: nil).in_batches(of: 1000) do |conversations|
        conversations.update_all(ai_assignee_type: 'AgentBot')
      end
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
