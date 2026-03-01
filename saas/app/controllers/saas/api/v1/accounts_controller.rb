class Saas::Api::V1::AccountsController < Api::V1::Accounts::BaseController
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

    render json: {
      plan: plan ? plan_payload(plan) : nil,
      subscription: subscription ? subscription_payload(subscription) : nil,
      usage: usage_payload(account)
    }
  end

  def plans
    plans = Saas::Plan.active.order(:price_cents)
    render json: plans.map { |p| plan_payload(p) }
  end

  private

  def plan_payload(plan)
    {
      id: plan.id,
      name: plan.name,
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

  def usage_payload(account)
    {
      agents: account.users.where(account_users: { role: :agent }).count,
      inboxes: account.inboxes.count,
      ai_tokens_used: account.ai_monthly_usage,
      ai_tokens_limit: account.saas_plan&.ai_tokens_monthly || 0,
      ai_tokens_remaining: account.ai_tokens_remaining
    }
  end
end
