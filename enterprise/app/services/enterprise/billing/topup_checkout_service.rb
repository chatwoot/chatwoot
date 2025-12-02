class Enterprise::Billing::TopupCheckoutService
  class Error < StandardError; end

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
    topup_option = validate_and_find_topup_option(credits)
    session = create_stripe_session(topup_option, credits)
    session.url
  end

  private

  def validate_and_find_topup_option(credits)
    raise Error, 'Invalid credits amount' unless credits.to_i.positive?

    validate_plan_eligibility!

    topup_option = find_topup_option(credits)
    raise Error, 'Invalid topup option' unless topup_option

    raise Error, 'Stripe customer not configured' if stripe_customer_id.blank?

    topup_option
  end

  def validate_plan_eligibility!
    plan_name = account.custom_attributes&.[]('plan_name')

    return if plan_name.present? && plan_name.downcase != 'hacker'

    raise Error, 'Top-ups are only available for Startup, Business, and Enterprise plans. Please upgrade your plan first.'
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
