module Enterprise::Api::V1::AccountsSettings
  def create
    super
    record_marketing_attribution
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

  def permitted_settings_attributes
    super + [
      { conversation_required_attributes: [] },
      { copilot: [:show_on_home, :assistant_id] }
    ]
  end

  # The account update replaces each top-level setting, so merge Copilot keys into the saved ones. A request that sends
  # only the home screen switch then keeps the saved assistant.
  def settings_params
    permitted = super
    return permitted unless permitted[:copilot].is_a?(ActionController::Parameters)

    saved = @account.settings['copilot'] || {}
    permitted.merge(copilot: saved.merge(permitted[:copilot].to_h))
  end
end
