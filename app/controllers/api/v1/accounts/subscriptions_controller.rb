class Api::V1::Accounts::SubscriptionsController < Api::V1::Accounts::BaseController
  before_action :authorize_billing

  def show
    render json: {
      subscription: subscription_payload,
      plan: Current.account.active_plan&.to_h,
      usage: Current.account.usage_summary,
      plans: PlanConfig.all.map(&:to_h)
    }
  end

  def checkout
    url = Current.account.checkout_url(
      params[:plan_key],
      success_url: billing_url(session_id: '{CHECKOUT_SESSION_ID}'),
      cancel_url: billing_url(cancelled: true)
    )
    render json: { checkout_url: url }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def portal
    url = Current.account.billing_portal_url(return_url: billing_url)
    render json: { portal_url: url }
  end

  def swap
    Current.account.swap_plan!(params[:plan_key])
    render json: { message: 'Plan updated' }
  rescue RuntimeError, ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def cancel
    Current.account.cancel_subscription!
    render json: { message: 'Subscription will cancel at period end' }
  rescue RuntimeError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def resume
    Current.account.resume_subscription!
    render json: { message: 'Subscription resumed' }
  rescue RuntimeError, Pay::FakeProcessor::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def authorize_billing
    authorize Current.account, :manage_billing?
  end

  def billing_url(**query)
    base = "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{Current.account.id}/settings/billing"
    query.any? ? "#{base}?#{query.to_query}" : base
  end

  def subscription_payload
    sub = Current.account.active_subscription
    return nil unless sub

    {
      status: sub.status,
      current_period_end: sub.current_period_end,
      trial_ends_at: sub.trial_ends_at,
      ends_at: sub.ends_at,
      on_grace_period: sub.on_grace_period?,
      processor_plan: sub.processor_plan
    }
  end
end
