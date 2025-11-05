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

    # Check if account has a valid subscription plan
    plan_validation = validate_subscription_plan
    return plan_validation unless plan_validation[:valid]

    topup_definition = Enterprise::Billing::V2::TopupCatalog.find_option(credits)
    return { valid: false, success: false, message: 'Unsupported topup amount' } unless topup_definition
    return { valid: false, success: false, message: 'Stripe customer not configured' } if stripe_customer_id.blank?

    # Check if customer has a default payment method using common service
    payment_service = Enterprise::Billing::V2::InvoicePaymentService.new(account: account)
    payment_method_validation = payment_service.validate_payment_method
    return payment_method_validation.merge(valid: false) if payment_method_validation

    { valid: true, topup_definition: topup_definition }
  end

  def validate_subscription_plan
    plan_name = custom_attribute('plan_name')

    # Block topup if no plan or on Hacker plan
    if plan_name.blank? || plan_name.downcase == 'hacker'
      return {
        valid: false,
        success: false,
        message: 'Top-ups are only available for Startup, Business, and Enterprise plans. Please upgrade your plan to purchase credits.'
      }
    end

    { valid: true }
  end

  def process_topup_transaction(credits, amount_cents, currency, amount)
    line_items = build_topup_line_items(credits, amount_cents)
    invoice_result = charge_topup_invoice(line_items, currency)
    return invoice_result unless invoice_result[:success]

    credit_grant = create_stripe_credit_grant(amount_cents, currency, credits)
    return { success: false, message: 'Failed to create credit grant in Stripe' } unless credit_grant

    build_success_response(credits, amount, currency, invoice_result[:invoice_id], credit_grant['id'])
  end

  def build_topup_line_items(credits, amount_cents)
    [{
      amount: amount_cents,
      description: "Credit Topup: #{credits} credits",
      metadata: {
        account_id: account.id.to_s,
        credits: credits.to_s,
        topup: 'true'
      }
    }]
  end

  def charge_topup_invoice(line_items, currency)
    payment_service = Enterprise::Billing::V2::InvoicePaymentService.new(account: account)
    payment_service.create_and_pay_invoice(
      line_items: line_items,
      description: 'Credit top-up purchase',
      currency: currency,
      metadata: {
        account_id: account.id.to_s,
        topup: 'true'
      }
    )
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

  # Create Credit Grant in Stripe using monetary amount (not custom_pricing_unit)
  # Following Stripe UBB Integration Guide section 8
  def create_stripe_credit_grant(amount_cents, currency, credits)
    Stripe::Billing::CreditGrant.create(
      credit_grant_params(amount_cents, currency, credits)
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
end
