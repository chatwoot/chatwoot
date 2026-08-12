class AddAiAssigneeTypeToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :ai_assignee_type, :string

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE conversations
          SET ai_assignee_type = 'AgentBot'
          WHERE assignee_agent_bot_id IS NOT NULL
        SQL
      end
    end
  end
end
