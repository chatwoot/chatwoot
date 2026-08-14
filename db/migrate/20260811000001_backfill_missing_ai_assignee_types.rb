class BackfillMissingAiAssigneeTypes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Catch AgentBot assignments created after the discriminator column was introduced.
    # rubocop:disable Rails/SkipsModelValidations
    Conversation.where(ai_assignee_type: nil).where.not(assignee_agent_bot_id: nil).in_batches(of: 1000) do |conversations|
      conversations.update_all(ai_assignee_type: 'AgentBot')
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
