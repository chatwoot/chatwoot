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

  def v2_enabled?
    custom_attribute('stripe_billing_version').to_i == 2
  end

  def v2_config
    Rails.application.config.stripe_v2 || {}
  end

  def monthly_credits
    custom_attribute('monthly_credits').to_i
  end

  def topup_credits
    custom_attribute('topup_credits').to_i
  end

  def update_credits(monthly: nil, topup: nil)
    updates = {}
    updates['monthly_credits'] = monthly unless monthly.nil?
    updates['topup_credits'] = topup unless topup.nil?
    update_custom_attributes(updates)
  end

  def update_custom_attributes(updates)
    return if updates.blank?

    current_attributes = account.custom_attributes.present? ? account.custom_attributes.deep_dup : {}
    updates.each do |key, value|
      current_attributes[key.to_s] = value
    end

    account.update!(custom_attributes: current_attributes)
  end

  def custom_attribute(key)
    account.custom_attributes&.[](key.to_s)
  end

  def with_locked_account(&)
    account.with_lock(&)
  end

  def log_credit_transaction(type:, amount:, credit_type:, description: nil, metadata: nil)
    account.credit_transactions.create!(
      transaction_type: type,
      amount: amount,
      credit_type: credit_type,
      description: description,
      metadata: (metadata || {}).stringify_keys
    )
  end

  def with_stripe_error_handling
    yield
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe V2 Error: #{e.message}"
    { success: false, message: e.message }
  end
end
