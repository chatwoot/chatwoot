class Enterprise::Ai::CaptainCreditService
  attr_reader :account, :conversation

  def initialize(account: nil, conversation: nil)
    @account = account || conversation&.account
    @conversation = conversation
  end

  def check_and_use_credits(feature: 'ai_captain', amount: 1, metadata: {})
    # V1 accounts don't use credit system
    return { success: true } unless v2_enabled?

    # V2 accounts use credit-based billing
    service = Enterprise::Billing::V2::CreditManagementService.new(account: account)
    result = service.use_credit(feature: feature, amount: amount, metadata: metadata)
    Rails.logger.info "Credit result: #{result.inspect}"
    result
  end

  private

  def v2_enabled?
    ENV.fetch('STRIPE_BILLING_V2_ENABLED', 'false') == 'true'
  end
end
