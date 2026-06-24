module Enterprise::Api::V1::AccountsSettings
  def create
    super
    record_marketing_attribution
    enqueue_marketing_signup_conversion
  end

  private

  def record_marketing_attribution
    return if current_user.present?
    return if @account.blank?

    Internal::Accounts::MarketingAttributionService.new(account: @account, cookies: cookies).perform
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end

  def enqueue_marketing_signup_conversion
    return if current_user.present?
    return if @account.blank?

    Internal::Accounts::MarketingConversionTrackingJob.perform_later(@account.id, 'cloud_signup', @account.created_at.iso8601)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
  end

  def permitted_settings_attributes
    super + [{ conversation_required_attributes: [] }]
  end
end
