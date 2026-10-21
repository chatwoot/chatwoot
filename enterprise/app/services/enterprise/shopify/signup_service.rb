module Enterprise::Shopify::SignupService
  private

  def create_account
    super.tap do |account|
      Enterprise::Billing::ShopifySubscriptionSyncService.new(account: account).suspend_pending_signup!
    end
  end
end
