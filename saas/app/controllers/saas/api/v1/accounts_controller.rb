class Saas::Api::V1::AccountsController < Api::V1::Accounts::BaseController
  # Member routes pass :id instead of :account_id; remap BEFORE
  # the parent's current_account filter tries Account.find(params[:account_id]).
  prepend_before_action :set_account_id_from_member_route
  before_action :check_admin_authorization?

  def checkout
    plan = Saas::Plan.active.find(params[:plan_id])
    session = Saas::StripeService.create_checkout_session(Current.account, plan)
    render json: { redirect_url: session.url }
  end

  def subscription
    session = Saas::StripeService.create_billing_portal_session(Current.account)
    render json: { redirect_url: session.url }
  end

  def limits
    account = Current.account
    plan = account.saas_plan
    subscription = account.saas_subscription
    limits = account.usage_limits

    agent_count = account.users.where(account_users: { role: :agent }).count
    inbox_count = account.inboxes.count

    render json: {
      plan: plan ? plan_payload(plan) : nil,
      subscription: subscription ? subscription_payload(subscription) : nil,
      usage: usage_payload(account, agent_count, inbox_count),
      # UpgradePage-compatible limits shape (allowed/consumed pairs)
      limits: {
        conversation: { allowed: Float::INFINITY, consumed: 0 },
        non_web_inboxes: { allowed: limits[:inboxes] || Float::INFINITY, consumed: inbox_count },
        agents: { allowed: limits[:agents] || Float::INFINITY, consumed: agent_count }
      }
    }
  end

  def plans
    plans = Saas::Plan.active.order(:price_cents)
    render json: plans.map { |p| plan_payload(p) }
  end

  private

  def set_account_id_from_member_route
    params[:account_id] ||= params[:id]
  end

  def plan_payload(plan)
    {
      id: plan.id,
      name: plan.name,
      base_name: plan.base_name,
      price_cents: plan.price_cents,
      interval: plan.interval,
      agent_limit: plan.agent_limit,
      inbox_limit: plan.inbox_limit,
      ai_tokens_monthly: plan.ai_tokens_monthly,
      features: plan.features
    }
  end

  def subscription_payload(subscription)
    {
      id: subscription.id,
      status: subscription.status,
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end,
      trial_end: subscription.trial_end
    }
  end

  def usage_payload(account, agent_count, inbox_count)
    {
      agents: agent_count,
      inboxes: inbox_count,
      ai_tokens_used: account.ai_monthly_usage,
      ai_tokens_limit: account.saas_plan&.ai_tokens_monthly || 0,
      ai_tokens_remaining: account.ai_tokens_remaining,
      ai_usage_percentage: account.ai_usage_percentage
    }
  end
end
