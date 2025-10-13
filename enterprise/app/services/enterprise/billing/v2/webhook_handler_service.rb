class Enterprise::Billing::V2::WebhookHandlerService < Enterprise::Billing::V2::BaseService
  def process(event)
    case event.type
    when 'billing.credit_grant.created'
      handle_credit_grant_created(event.data.object)
    when 'billing.credit_grant.updated'
      handle_credit_grant_updated(event.data.object)
    else
      { success: true }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  private

  def handle_credit_grant_created(grant)
    amount = extract_credit_amount(grant)
    return { success: true } if amount.zero?

    service = Enterprise::Billing::V2::CreditManagementService.new(account: account)

    if grant.expires_at.present?
      service.sync_monthly_credits(amount)
    else
      service.add_topup_credits(amount)
    end

    { success: true }
  end

  def handle_credit_grant_updated(grant)
    # Check if grant has expired
    if grant.respond_to?(:expired_at) && grant.expired_at
      # Grant has expired
      handle_credit_grant_expired
    else
      # Other updates (voided, amount changes, etc)
      { success: true }
    end
  end

  def handle_credit_grant_expired
    Enterprise::Billing::V2::CreditManagementService.new(account: account).expire_monthly_credits
    { success: true }
  end

  def extract_credit_amount(grant)
    # Handle both Hash and OpenStruct response formats
    amount_data = grant.respond_to?(:amount) ? grant.amount : grant['amount']
    return 0 unless amount_data

    # Extract value from nested structure
    if amount_data.is_a?(Hash)
      amount_data.dig('custom_pricing_unit', 'value').to_i
    elsif amount_data.respond_to?(:custom_pricing_unit)
      amount_data.custom_pricing_unit&.value.to_i
    else
      0
    end
  end
end
