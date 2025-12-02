class Enterprise::Billing::TopupCheckoutService
  include BillingHelper
  include Rails.application.routes.url_helpers

  class Error < StandardError; end

  TOPUP_OPTIONS = [
    { credits: 1000, amount: 20.0, currency: 'usd' },
    { credits: 2500, amount: 50.0, currency: 'usd' },
    { credits: 6000, amount: 100.0, currency: 'usd' },
    { credits: 12_000, amount: 200.0, currency: 'usd' }
  ].freeze

  pattr_initialize [:account!]

  def create_checkout_session(credits:)
    topup_option = validate_and_find_topup_option(credits)
    session = create_stripe_session(topup_option, credits)
    session.url
  end

  private

  def validate_and_find_topup_option(credits)
    raise Error, I18n.t('errors.topup.invalid_credits') unless credits.to_i.positive?
    raise Error, I18n.t('errors.topup.plan_not_eligible') if default_plan?(account)

    topup_option = find_topup_option(credits)
    raise Error, I18n.t('errors.topup.invalid_option') unless topup_option

    topup_option
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
        description: "AI Credit Topup: #{credits} credits",
        metadata: session_metadata(credits, topup_option)
      }
    }
  end

  def build_line_item(topup_option, credits)
    {
      price_data: {
        currency: topup_option[:currency],
        unit_amount: (topup_option[:amount] * 100).to_i,
        product_data: { name: "AI Credit Topup: #{credits} credits" }
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
    app_account_billing_settings_url(account_id: account.id, topup: 'success')
  end

  def cancel_url
    app_account_billing_settings_url(account_id: account.id)
  end

  def stripe_customer_id
    account.custom_attributes['stripe_customer_id']
  end

  def find_topup_option(credits)
    TOPUP_OPTIONS.find { |opt| opt[:credits] == credits.to_i }
  end
end
