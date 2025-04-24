class V2::Reports::AiAgentMetricsBuilder
  # This class is responsible for building AI agent metrics for a given account and parameters.
  # It includes the DateRangeHelper module to handle date range calculations.

  # Include the DateRangeHelper module to provide date range functionality
  include DateRangeHelper
  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params = params
  end

  def metrics
    {
      conversation_count: bot_conversations.count,
      message_count: bot_messages.count,
      resolution_rate: bot_resolution_rate.to_i,
      handoff_rate: bot_handoff_rate.to_i
    }
  end

  def summary
    {
      ai_agent_credit_usage: ai_agent_credit_usage,
      ai_agent_message_send_count: ai_message_send_count
    }
  end

  private

  def ai_agent_ids
    @ai_agent_ids ||= account.ai_agents.pluck(:id)
  end

  def ai_agent_credit_usage
    account.messages.where(sender_type: 'AiAgent', sender_id: ai_agent_ids).where(created_at: range).count
  end

  def ai_message_send_count
    account.messages.where(sender_type: 'AiAgent', sender_id: ai_agent_ids).where(created_at: range).count
  end
end
