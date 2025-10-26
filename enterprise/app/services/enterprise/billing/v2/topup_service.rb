class Enterprise::Billing::V2::TopupService < Enterprise::Billing::V2::BaseService
  def create_topup(credits:)
    validation_result = validate_topup_request(credits)
    return validation_result unless validation_result[:valid]

    topup_definition = validation_result[:topup_definition]
    amount_cents = (topup_definition[:amount] * 100).to_i
    currency = topup_definition[:currency] || 'usd'

    with_locked_account do
      process_topup_transaction(credits, amount_cents, currency, topup_definition[:amount])
    end
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe error: #{e.message}" }
  end

  private

  def validate_topup_request(credits)
    return { valid: false, success: false, message: 'Invalid topup amount' } unless credits.to_i.positive?

    topup_definition = Enterprise::Billing::V2::TopupCatalog.find_option(credits)
    return { valid: false, success: false, message: 'Unsupported topup amount' } unless topup_definition
    return { valid: false, success: false, message: 'Stripe customer not configured' } if stripe_customer_id.blank?

    { valid: true, topup_definition: topup_definition }
  end

  def process_topup_transaction(credits, amount_cents, currency, amount)
    invoice = create_topup_invoice(currency)
    return { success: false, message: 'Failed to create invoice' } unless invoice

    invoice_item = create_topup_invoice_item(invoice.id, amount_cents, currency, credits)
    return { success: false, message: 'Failed to create invoice item' } unless invoice_item

    finalized_invoice = finalize_topup_invoice(invoice.id)
    return { success: false, message: 'Failed to finalize invoice' } unless finalized_invoice

    paid_invoice = pay_invoice(invoice.id)
    return { success: false, message: 'Failed to pay invoice' } unless paid_invoice

    credit_grant = create_stripe_credit_grant(amount_cents, currency, credits)
    return { success: false, message: 'Failed to create credit grant in Stripe' } unless credit_grant

    # Credits will be added by webhook when Stripe sends billing.credit_grant.created event
    build_success_response(credits, amount, currency, invoice.id, credit_grant['id'])
  end

  def build_success_response(credits, amount, currency, invoice_id, credit_grant_id)
    {
      success: true,
      message: 'Top-up purchased successfully',
      credits: credits,
      amount: amount,
      currency: currency,
      invoice_id: invoice_id,
      credit_grant_id: credit_grant_id
    }
  end

  # Create Invoice following Stripe UBB Integration Guide
  def create_topup_invoice(currency)
    Stripe::Invoice.create(
      {
        customer: stripe_customer_id,
        currency: currency,
        collection_method: 'charge_automatically',
        auto_advance: false, # We'll finalize it manually
        metadata: {
          account_id: account.id.to_s,
          topup: 'true'
        }
      },
      stripe_api_options
    )
  end

  # Create Invoice Item with topup amount
  def create_topup_invoice_item(invoice_id, amount_cents, currency, credits)
    Stripe::InvoiceItem.create(
      {
        customer: stripe_customer_id,
        amount: amount_cents,
        currency: currency,
        invoice: invoice_id,
        description: "Credit Topup: #{credits} credits",
        metadata: {
          account_id: account.id.to_s,
          credits: credits.to_s,
          topup: 'true'
        }
      },
      stripe_api_options
    )
  end

  # Finalize Invoice for payment
  def finalize_topup_invoice(invoice_id)
    Stripe::Invoice.finalize_invoice(
      invoice_id,
      { auto_advance: false }, # We'll pay it explicitly
      stripe_api_options
    )
  end

  # Pay the invoice explicitly
  def pay_invoice(invoice_id)
    Stripe::Invoice.pay(
      invoice_id,
      {},
      stripe_api_options
    )
  end

  # Create Credit Grant in Stripe using monetary amount (not custom_pricing_unit)
  # Following Stripe UBB Integration Guide section 8
  def create_stripe_credit_grant(amount_cents, currency, credits)
    Stripe::Billing::CreditGrant.create(
      credit_grant_params(amount_cents, currency, credits),
      stripe_api_options
    )
  end

  def credit_grant_params(amount_cents, currency, credits)
    {
      customer: stripe_customer_id,
      name: "Topup: #{credits} credits",
      amount: credit_grant_amount(amount_cents, currency),
      applicability_config: credit_grant_applicability,
      category: 'paid',
      metadata: credit_grant_metadata(credits)
    }
  end

  def credit_grant_amount(amount_cents, currency)
    {
      type: 'monetary',
      monetary: {
        currency: currency,
        value: amount_cents
      }
    }
  end

  def credit_grant_applicability
    # Apply credit grant to all metered usage for this customer
    # This ensures topup credits offset meter-based billing
    {
      scope: {
        price_type: 'metered'
      }
    }
  end

  def credit_grant_metadata(credits)
    {
      account_id: account.id.to_s,
      source: 'topup',
      credits: credits.to_s
    }
  end

  def stripe_customer_id
    custom_attribute('stripe_customer_id')
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end
end
