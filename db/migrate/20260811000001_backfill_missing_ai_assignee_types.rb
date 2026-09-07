class BackfillMissingAiAssigneeTypes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Reconcile AgentBot assignments changed while the discriminator release was rolling out.
    # rubocop:disable Rails/SkipsModelValidations
    Conversation.in_batches(of: 100_000, use_ranges: true) do |conversation_range|
      conversation_range.where(ai_assignee_type: nil).where.not(assignee_agent_bot_id: nil).in_batches(of: 1000) do |conversations|
        conversations.update_all(ai_assignee_type: 'AgentBot')
      end

      conversation_range.where(ai_assignee_type: 'AgentBot', assignee_agent_bot_id: nil).in_batches(of: 1000) do |conversations|
        conversations.update_all(ai_assignee_type: nil)
      end
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
