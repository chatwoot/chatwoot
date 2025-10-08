class Enterprise::Billing::V2::WebhookHandlerService < Enterprise::Billing::V2::BaseService
  def process(event)
    Rails.logger.info "Processing V2 billing event: #{event.type}"

    case event.type
    when 'billing.credit_grant.created'
      handle_credit_grant_created(event)
    when 'billing.credit_grant.expired'
      handle_credit_grant_expired(event)
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event)
    when 'invoice.payment_failed'
      handle_payment_failed(event)
    else
      Rails.logger.info "Event type not handled: #{event.type}"
      { success: true }
    end
  rescue StandardError => e
    Rails.logger.error "Error processing V2 webhook: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def handle_credit_grant_created(event)
    return { success: true } if processed_event?(event.id)

    grant = event.data.object
    amount = extract_credit_amount(grant)
    return { success: true } if amount.zero?

    metadata = event_metadata(event, grant_id: grant.respond_to?(:id) ? grant.id : nil)
    credit_service = Enterprise::Billing::V2::CreditManagementService.new(account: account)

    if monthly_grant?(grant)
      credit_service.grant_monthly_credits(amount, metadata: metadata)
      Rails.logger.info "Granted #{amount} monthly credits to account #{account.id}"
    else
      credit_service.add_topup_credits(amount, metadata: metadata.merge('source' => 'credit_grant'))
      Rails.logger.info "Added #{amount} topup credits to account #{account.id} via credit grant"
    end

    { success: true }
  end

  def handle_credit_grant_expired(_event)
    Enterprise::Billing::V2::CreditManagementService.new(account: account).expire_monthly_credits
    Rails.logger.info "Expired monthly credits for account #{account.id}"
    { success: true }
  end

  def handle_payment_succeeded(event)
    return { success: true } if processed_event?(event.id)

    invoice = event.data.object

    # Check if this is a topup payment
    return { success: true } unless invoice_metadata(invoice, 'type') == 'topup'

    credits = invoice_metadata(invoice, 'credits').to_i
    return { success: true } if credits.zero?

    metadata = event_metadata(event, invoice_id: invoice.id)
    Enterprise::Billing::V2::CreditManagementService.new(account: account)
                                                    .add_topup_credits(credits, metadata: metadata.merge('source' => 'invoice'))
    Rails.logger.info "Added #{credits} topup credits for account #{account.id}"
    { success: true }
  end

  def handle_payment_failed(event)
    invoice = event.data.object
    Rails.logger.error "Payment failed for account #{account.id}: #{invoice.id}"

    # Update subscription status
    account.custom_attributes['subscription_status'] = 'past_due'
    account.save!
    { success: true }
  end

  def processed_event?(event_id)
    account.credit_transactions.exists?(["metadata ->> 'stripe_event_id' = ?", event_id])
  end

  def extract_credit_amount(grant)
    return grant.amount.to_i if grant.respond_to?(:amount) && grant.amount.is_a?(Numeric)

    raw = grant.respond_to?(:amount) ? grant.amount : grant['amount']
    return 0 if raw.blank?

    return hash_amount_value(raw) if raw.is_a?(Hash) || raw.respond_to?(:[])

    raw.to_i
  end

  def hash_amount_value(raw)
    cpu = raw['custom_pricing_unit'] || raw[:custom_pricing_unit]
    return cpu['value'].to_i if cpu.present?
    return raw['value'].to_i if raw['value']

    0
  end

  def monthly_grant?(grant)
    grant.respond_to?(:expires_at) && grant.expires_at.present?
  end

  def event_metadata(event, extra = {})
    { 'stripe_event_id' => event.id }.merge(extra.compact.transform_keys(&:to_s))
  end

  def invoice_metadata(invoice, key)
    return unless invoice.respond_to?(:metadata)

    metadata = invoice.metadata
    return metadata[key] if metadata.respond_to?(:[])

    nil
  end
end
