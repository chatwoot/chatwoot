class Enterprise::Ai::CaptainCreditService
  attr_reader :account, :conversation

  def initialize(account: nil, conversation: nil)
    @account = account || conversation&.account
    @conversation = conversation
  end

  def check_and_use_credits(feature: 'ai_captain', amount: 1, metadata: {})
    # V1 accounts don't use credit system
    return { success: true } if account.custom_attributes['stripe_billing_version'].to_i != 2

    # V2 accounts use credit-based billing
    service = Enterprise::Billing::V2::CreditManagementService.new(account: account)
    service.use_credit(feature: feature, amount: amount, metadata: metadata)
  end
end
