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
      ai_agent_credit_usage: ai_agent_credit_usage,
      ai_agent_message_send_count: ai_agent_message_send_count,
      ai_agent_handoff_count: ai_agent_handoff_count,
      human_agent_handoff_count: human_agent_handoff_count
    }
  end

  private

  def ai_agent_ids
    @ai_agent_ids ||= account.ai_agents.pluck(:id)
  end

  def agent_ids
    @agent_ids ||= account.agents.pluck(:id)
  end

  def ai_agent_credit_usage
    account.messages.where(sender_type: 'AiAgent', sender_id: ai_agent_ids).where(created_at: range).count
  end

  def ai_agent_message_send_count
    account.messages.where(sender_type: 'AiAgent', sender_id: ai_agent_ids).where(created_at: range).count
  end

  def ai_agent_handoff_count
    account.messages
           .where(sender_type: 'AiAgent', sender_id: ai_agent_ids)
           .where(created_at: range)
           .distinct
           .count(:sender_id)
  end

  def human_agent_handoff_count
    account.messages
           .where(sender_type: 'User', sender_id: agent_ids)
           .where(created_at: range)
           .distinct
           .count(:sender_id)
  end
end
