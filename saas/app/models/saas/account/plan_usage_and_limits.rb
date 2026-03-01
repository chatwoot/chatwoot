module Saas::Account::PlanUsageAndLimits
  def usage_limits
    return super unless saas_subscription&.active_or_trialing?

    saas_subscription.usage_limits
  end

  def ai_tokens_remaining
    return Float::INFINITY unless saas_plan

    limit = saas_plan.ai_tokens_monthly
    used = Saas::AiUsageRecord.monthly_usage(id)
    [limit - used, 0].max
  end

  def ai_usage_exceeded?
    return false unless saas_plan

    ai_tokens_remaining <= 0
  end

  def ai_monthly_usage
    Saas::AiUsageRecord.monthly_usage(id)
  end

  private

  def validate_limit_keys
    return unless limits.present?

    current_plan = saas_plan
    return unless current_plan

    errors.add(:limits, 'agent limit exceeds plan') if limits['agents'].to_i > current_plan.agent_limit
    errors.add(:limits, 'inbox limit exceeds plan') if limits['inboxes'].to_i > current_plan.inbox_limit
  end
end
