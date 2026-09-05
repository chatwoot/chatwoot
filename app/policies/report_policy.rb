class ReportPolicy < ApplicationPolicy
  AGENT_ALLOWED_ACTIONS = %w[
    overview_summary
    agent_activity
    agents
    labels
    agent
    label
    conversation_metrics
    grouped_conversation_metrics
  ].freeze

  AGENT_ALLOWED_TYPES = %w[agent label account].freeze
  SHARED_ACTIONS = %w[index summary].freeze

  def view?
    return true if @account_user.administrator?
    return false unless @account_user.agent?

    agent_can_view?
  end

  private

  def agent_can_view?
    return true if AGENT_ALLOWED_ACTIONS.include?(record_action)
    return AGENT_ALLOWED_TYPES.include?(record_type) if SHARED_ACTIONS.include?(record_action)

    false
  end

  def record_action
    record.is_a?(Hash) ? record[:action].to_s : ''
  end

  def record_type
    record.is_a?(Hash) ? record[:type].to_s : ''
  end
end

ReportPolicy.prepend_mod_with('ReportPolicy')
