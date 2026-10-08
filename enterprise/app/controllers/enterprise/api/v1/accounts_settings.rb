module Enterprise::Api::V1::AccountsSettings
  def create
    super
    record_marketing_attribution
    start_cloud_trial
  end

  private

  # The upgrade banner is a self-hosted nudge; the managed cloud instance is always current.
  def latest_chatwoot_version
    return if ChatwootApp.chatwoot_cloud?

    super
  end

  def record_marketing_attribution
    return if current_user.present?
    return if @account.blank?

    Internal::Accounts::MarketingAttributionService.new(account: @account, cookies: cookies).perform
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end

  # Starts the free trial at signup instead of on the first billing page visit. Accounts that must pick a
  # billing currency first start it once they choose one there.
  def start_cloud_trial
    return unless @account&.persisted? && Enterprise::Billing::TrialService.enabled?
    return if @account.billing_provider != Account::DEFAULT_BILLING_PROVIDER || @account.billing_currency_selection_required?

    @account.update!(custom_attributes: @account.custom_attributes.merge('is_creating_customer' => true))
    Enterprise::CreateStripeCustomerJob.perform_later(@account)
  end

  def permitted_settings_attributes
    super + [{ conversation_required_attributes: [] }]
  end
end
