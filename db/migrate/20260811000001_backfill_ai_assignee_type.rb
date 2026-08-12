class BackfillAiAssigneeType < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    conversation_model = Class.new(ActiveRecord::Base) { self.table_name = 'conversations' }

    # rubocop:disable Rails/SkipsModelValidations
    conversation_model.where.not(assignee_agent_bot_id: nil).in_batches(of: 1000) do |conversations|
      conversations.update_all(ai_assignee_type: 'AgentBot')
    end
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down; end
end
