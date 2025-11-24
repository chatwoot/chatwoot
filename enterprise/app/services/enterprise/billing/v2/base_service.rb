class Enterprise::Billing::V2::BaseService
  attr_reader :account

  def initialize(account:)
    @account = account
  end

  private

  def stripe_client
    @stripe_client ||= Stripe::StripeClient.new(
      api_key: ENV.fetch('STRIPE_SECRET_KEY', nil)
    )
  end

  def response_monthly_credits
    account.limits&.[]('captain_responses_monthly').to_i
  end

  def response_topup_credits
    account.limits&.[]('captain_responses_topup').to_i
  end

  def response_usage
    account.custom_attributes&.[]('captain_responses_usage').to_i
  end

  # Update response credits (monthly/topup with auto-calculation of total)
  def update_response_credits(monthly: nil, topup: nil)
    # Calculate and update total in limits hash ONLY
    return if monthly.nil? && topup.nil?

    new_monthly = monthly || response_monthly_credits
    new_topup = topup || response_topup_credits
    total_credits = new_monthly + new_topup
    limits = {
      'captain_responses_monthly' => new_monthly,
      'captain_responses_topup' => new_topup,
      'captain_responses' => total_credits
    }
    update_limits(limits)
  end

  def update_limits(updates)
    return if updates.blank?

    account.update!(limits: (account.limits || {}).merge(updates.transform_keys(&:to_s)))
  end

  def update_custom_attributes(updates)
    return if updates.blank?

    account.update!(custom_attributes: (account.custom_attributes || {}).merge(updates.transform_keys(&:to_s)))
  end

  def custom_attribute(key)
    account.custom_attributes&.[](key.to_s)
  end

  def with_locked_account(&)
    account.with_lock(&)
  end

  # Convenient accessors for common attributes
  def stripe_customer_id
    custom_attribute('stripe_customer_id')
  end

  def stripe_subscription_id
    custom_attribute('stripe_subscription_id')
  end

  def pricing_plan_id
    custom_attribute('stripe_pricing_plan_id')
  end

  def subscribed_quantity
    custom_attribute('subscribed_quantity').to_i
  end
end
