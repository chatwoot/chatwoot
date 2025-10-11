class Enterprise::Billing::V2::WebhookHandlerService < Enterprise::Billing::V2::BaseService
  def process(event)
    case event.type
    when 'billing.credit_grant.created'
      handle_credit_grant_created(event.data.object)
    when 'billing.credit_grant.expired'
      handle_credit_grant_expired
    else
      { success: true }
    end
  rescue StandardError => e
    Rails.logger.error "V2 webhook error: #{e.message}"
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

  def handle_credit_grant_expired
    expired = Enterprise::Billing::V2::CreditManagementService.new(account: account).expire_monthly_credits
    Rails.logger.info "Expired #{expired} monthly credits for account #{account.id}"
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
