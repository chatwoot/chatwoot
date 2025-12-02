class Enterprise::Billing::TopupCheckoutService
  TOPUP_OPTIONS = [
    { credits: 1000, amount: 20.0, currency: 'usd' },
    { credits: 2500, amount: 50.0, currency: 'usd' },
    { credits: 5000, amount: 100.0, currency: 'usd' },
    { credits: 10_000, amount: 200.0, currency: 'usd' }
  ].freeze

  attr_reader :account

  def initialize(account:)
    @account = account
  end

  def create_checkout_session(credits:)
    validation_result = validate_request(credits)
    return validation_result unless validation_result[:valid]

    topup_option = validation_result[:topup_option]
    session = create_stripe_session(topup_option, credits)

    { success: true, redirect_url: session.url }
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe error: #{e.message}" }
  end

  private

  def validate_request(credits)
    return { valid: false, success: false, message: 'Invalid credits amount' } unless credits.to_i.positive?

    plan_validation = validate_plan_eligibility
    return plan_validation unless plan_validation[:valid]

    topup_option = find_topup_option(credits)
    return { valid: false, success: false, message: 'Invalid topup option' } unless topup_option

    return { valid: false, success: false, message: 'Stripe customer not configured' } if stripe_customer_id.blank?

    { valid: true, topup_option: topup_option }
  end

  def validate_plan_eligibility
    plan_name = account.custom_attributes&.[]('plan_name')

    if plan_name.blank? || plan_name.downcase == 'hacker'
      return {
        valid: false,
        success: false,
        message: 'Top-ups are only available for Startup, Business, and Enterprise plans. Please upgrade your plan first.'
      }
    end

    { valid: true }
  end

  def create_stripe_session(topup_option, credits)
    Stripe::Checkout::Session.create(
      customer: stripe_customer_id,
      mode: 'payment',
      line_items: [build_line_item(topup_option, credits)],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: session_metadata(credits, topup_option),
      payment_method_types: ['card'],
      # Show saved payment methods and allow saving new ones
      saved_payment_method_options: {
        payment_method_save: 'enabled',
        allow_redisplay_filters: %w[always limited]
      },
      # Create invoice for this payment so it appears in customer portal
      invoice_creation: build_invoice_creation_data(credits, topup_option)
    )
  end

  def build_invoice_creation_data(credits, topup_option)
    {
      enabled: true,
      invoice_data: {
        description: "Credit Topup: #{credits} credits",
        metadata: session_metadata(credits, topup_option)
      }
    }
  end

  def build_line_item(topup_option, credits)
    {
      price_data: {
        currency: topup_option[:currency],
        unit_amount: (topup_option[:amount] * 100).to_i,
        product_data: { name: "Credit Topup: #{credits} credits" }
      },
      quantity: 1
    }
  end

  def session_metadata(credits, topup_option)
    {
      account_id: account.id.to_s,
      credits: credits.to_s,
      amount_cents: (topup_option[:amount] * 100).to_s,
      currency: topup_option[:currency],
      topup: 'true'
    }
  end

  def success_url
    "#{base_url}/app/accounts/#{account.id}/settings/billing?topup=success"
  end

  def cancel_url
    "#{base_url}/app/accounts/#{account.id}/settings/billing"
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def stripe_customer_id
    account.custom_attributes&.[]('stripe_customer_id')
  end

  def find_topup_option(credits)
    TOPUP_OPTIONS.find { |opt| opt[:credits] == credits.to_i }
  end
end
