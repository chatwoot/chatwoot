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
    ENV.fetch('STRIPE_BILLING_V2_ENABLED', 'false') == 'true'
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
end
