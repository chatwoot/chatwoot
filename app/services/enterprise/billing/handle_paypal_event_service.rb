class Enterprise::Billing::HandlePaypalEventService
  PAYPAL_PLAN_MAPPING = {
    'P-BASIC-MONTHLY' => 'basic',
    'P-PRO-MONTHLY' => 'pro', 
    'P-PREMIUM-MONTHLY' => 'premium',
    'P-APP-MONTHLY' => 'app',
    'P-CUSTOM-MONTHLY' => 'custom'
  }.freeze

  def perform(event_type:, data:)
    @event_type = event_type
    @data = data

    case @event_type
    when 'subscription_activated'
      process_subscription_activated
    when 'subscription_updated'
      process_subscription_updated
    when 'subscription_cancelled'
      process_subscription_cancelled
    when 'subscription_suspended'
      process_subscription_suspended
    when 'payment_completed'
      process_payment_completed
    else
      Rails.logger.debug { "Unhandled PayPal event type: #{@event_type}" }
    end
  end

  private

  def process_subscription_activated
    return unless subscription && account

    create_or_update_subscription(status: 'active')
    update_account_plan
    enable_plan_features
    Rails.logger.info "PayPal subscription activated for account #{account.id}"
  end

  def process_subscription_updated
    return unless subscription && account

    update_subscription_from_paypal
    update_account_plan
    enable_plan_features
    Rails.logger.info "PayPal subscription updated for account #{account.id}"
  end

  def process_subscription_cancelled
    return unless subscription && account

    subscription.update!(status: 'canceled')
    suspend_account_access
    Rails.logger.info "PayPal subscription cancelled for account #{account.id}"
  end

  def process_subscription_suspended
    return unless subscription && account

    subscription.update!(status: 'past_due')
    suspend_account_access
    Rails.logger.info "PayPal subscription suspended for account #{account.id}"
  end

  def process_payment_completed
    return unless subscription && account

    subscription.update!(status: 'active') if subscription.past_due?
    enable_plan_features if subscription.active?
    Rails.logger.info "PayPal payment completed for account #{account.id}"
  end

  def create_or_update_subscription(status:)
    subscription_attrs = {
      account: account,
      external_id: @data['id'],
      provider: 'paypal',
      plan_key: map_paypal_plan(@data['plan_id']),
      status: status,
      current_period_start: parse_time(@data['start_time']),
      current_period_end: parse_time(@data.dig('billing_info', 'next_billing_time')),
      quantity: @data.dig('quantity') || 1,
      metadata: @data.except('id', 'plan_id', 'start_time', 'quantity')
    }

    if subscription
      subscription.update!(subscription_attrs.except(:account, :external_id, :provider))
    else
      Subscription.create!(subscription_attrs)
    end
  end

  def update_subscription_from_paypal
    return unless subscription

    subscription.update!(
      plan_key: map_paypal_plan(@data['plan_id']),
      status: map_paypal_status(@data['status']),
      current_period_end: parse_time(@data.dig('billing_info', 'next_billing_time')),
      quantity: @data.dig('quantity') || subscription.quantity,
      metadata: @data.except('id', 'plan_id', 'status', 'quantity')
    )
  end

  def update_account_plan
    return unless account && subscription

    weave_plan = account.weave_core_account_plans.first_or_initialize
    weave_plan.update!(
      plan_key: subscription.plan_key,
      status: subscription.trial? ? 'trial' : 'active'
    )
  end

  def enable_plan_features
    return unless account && subscription

    service = Enterprise::Billing::HandleStripeEventService.new
    service.instance_variable_set(:@account, account)
    service.send(:update_plan_features)
  end

  def suspend_account_access
    return unless account

    account.suspended!
    disable_all_features
  end

  def disable_all_features
    startup_features = Enterprise::Billing::HandleStripeEventService::STARTUP_PLAN_FEATURES
    business_features = Enterprise::Billing::HandleStripeEventService::BUSINESS_PLAN_FEATURES  
    enterprise_features = Enterprise::Billing::HandleStripeEventService::ENTERPRISE_PLAN_FEATURES

    account.disable_features(*(startup_features + business_features + enterprise_features))
    account.save!
  end

  def subscription
    @subscription ||= Subscription.find_by(external_id: @data['id'], provider: 'paypal')
  end

  def account
    @account ||= begin
      return nil unless subscription

      subscription.account
    end
  end

  def map_paypal_plan(paypal_plan_id)
    PAYPAL_PLAN_MAPPING[paypal_plan_id] || 'basic'
  end

  def map_paypal_status(paypal_status)
    case paypal_status&.upcase
    when 'ACTIVE'
      'active'
    when 'CANCELLED', 'CANCELED'
      'canceled'
    when 'SUSPENDED'
      'past_due'
    when 'PENDING'
      'trial'
    else
      'active'
    end
  end

  def parse_time(time_string)
    return nil unless time_string

    Time.parse(time_string)
  rescue ArgumentError
    nil
  end
end