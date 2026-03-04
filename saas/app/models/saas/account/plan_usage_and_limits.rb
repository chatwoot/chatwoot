module Saas::Account::PlanUsageAndLimits
  # Minimum limits for suspended (past_due/unpaid/canceled) accounts:
  # they keep existing data but cannot add new agents/inboxes.
  SUSPENDED_LIMITS = { agents: 0, inboxes: 0, ai_tokens_monthly: 0 }.freeze

  def usage_limits
    return super unless saas_subscription

    # Suspended accounts get zero limits (can't create anything new)
    return SUSPENDED_LIMITS if saas_subscription_suspended?

    # Active/trialing accounts get plan limits
    return saas_subscription.usage_limits if saas_subscription.active_or_trialing?

    # No recognized status — fall back to base
    super
  end

  def saas_subscription_suspended?
    saas_subscription&.past_due? || saas_subscription&.unpaid? || saas_subscription&.canceled?
  end

  def ai_tokens_remaining
    return Float::INFINITY unless saas_plan
    return 0 if saas_subscription_suspended?

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

  def ai_usage_percentage
    return 0 unless saas_plan
    return 0 if saas_plan.ai_tokens_monthly.zero?

    ((ai_monthly_usage.to_f / saas_plan.ai_tokens_monthly) * 100).round(1)
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
