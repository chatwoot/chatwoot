module Enterprise::Api::V1::AccountsSettings
  def create
    super
    record_marketing_attribution
  end

  private

  def record_marketing_attribution
    return if current_user.present?
    return if @account.blank?

    Internal::Accounts::MarketingAttributionService.new(account: @account, cookies: cookies).perform
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end

  def permitted_settings_attributes
    super + [{ conversation_required_attributes: [] }]
  end
end
