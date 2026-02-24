class Enterprise::Billing::TopupCheckoutService
  include BillingHelper

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
    charge_customer(topup_option, credits)
    fulfill_credits(credits, topup_option)

    {
      credits: credits,
      amount: topup_option[:amount],
      currency: topup_option[:currency]
    }
  end

  private

  def validate_and_find_topup_option(credits)
    raise Error, I18n.t('errors.topup.invalid_credits') unless credits.to_i.positive?
    raise Error, I18n.t('errors.topup.plan_not_eligible') if default_plan?(account)
    raise Error, I18n.t('errors.topup.stripe_customer_not_configured') if stripe_customer_id.blank?

    topup_option = find_topup_option(credits)
    raise Error, I18n.t('errors.topup.invalid_option') unless topup_option

    # Validate payment method exists
    validate_payment_method!

    topup_option
  end

  def validate_payment_method!
    customer = Stripe::Customer.retrieve(stripe_customer_id)

    return if customer.invoice_settings.default_payment_method.present? || customer.default_source.present?

    # Auto-set first payment method as default if available
    payment_methods = Stripe::PaymentMethod.list(customer: stripe_customer_id, limit: 1)
    raise Error, I18n.t('errors.topup.no_payment_method') if payment_methods.data.empty?

    Stripe::Customer.update(stripe_customer_id, invoice_settings: { default_payment_method: payment_methods.data.first.id })
  end

  def charge_customer(topup_option, credits)
    amount_cents = (topup_option[:amount] * 100).to_i
    currency = topup_option[:currency]
    description = "AI Credits Topup: #{credits} credits"

    invoice = Stripe::Invoice.create(
      customer: stripe_customer_id,
      currency: currency,
      collection_method: 'charge_automatically',
      auto_advance: false,
      description: description
    )

    Stripe::InvoiceItem.create(
      customer: stripe_customer_id,
      amount: amount_cents,
      currency: currency,
      invoice: invoice.id,
      description: description
    )

    Stripe::Invoice.finalize_invoice(invoice.id, { auto_advance: false })
    Stripe::Invoice.pay(invoice.id)
  end

  def fulfill_credits(credits, topup_option)
    Enterprise::Billing::TopupFulfillmentService.new(account: account).fulfill(
      credits: credits,
      amount_cents: (topup_option[:amount] * 100).to_i,
      currency: topup_option[:currency]
    )
  end

  def stripe_customer_id
    account.custom_attributes['stripe_customer_id']
  end

  def find_topup_option(credits)
    TOPUP_OPTIONS.find { |opt| opt[:credits] == credits.to_i }
  end
end
