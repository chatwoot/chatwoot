class Enterprise::Billing::V2::WebhookHandlerService < Enterprise::Billing::V2::BaseService
  def process(event)
    case event.type
    when 'billing.credit_grant.created'
      handle_credit_grant_created(event)
    when 'billing.credit_grant.expired'
      handle_credit_grant_expired(event)
    else
      { success: true }
    end
  rescue StandardError => e
    Rails.logger.error "Error processing V2 webhook: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def handle_credit_grant_created(event)
    grant = event.data.object
    amount = extract_amount(grant)
    return { success: true } if amount.zero?

    credit_service = Enterprise::Billing::V2::CreditManagementService.new(account: account)

    if grant_expires?(grant)
      # Monthly grant from Stripe service action
      credit_service.sync_monthly_credits(amount)
    else
      # Topup grant
      credit_service.add_topup_credits(amount)
    end

    { success: true }
  end

  def handle_credit_grant_expired(_event)
    expired = Enterprise::Billing::V2::CreditManagementService.new(account: account).sync_monthly_expired
    Rails.logger.info "Expired #{expired} monthly credits for account #{account.id}"
    { success: true }
  end

  def extract_amount(grant)
    return 0 unless grant.respond_to?(:amount)

    if grant.amount.is_a?(Hash)
      grant.amount.dig('custom_pricing_unit', 'value').to_i
    else
      grant.amount.to_i
    end
  end

  def grant_expires?(grant)
    grant.respond_to?(:expires_at) && grant.expires_at.present?
  end
end
