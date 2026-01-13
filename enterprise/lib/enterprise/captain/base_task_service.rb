module Enterprise::Captain::BaseTaskService
  def perform
    return { error: I18n.t('captain.copilot_limit'), error_code: 429 } unless responses_available?

    unless captain_enabled?
      return { error: I18n.t('captain.upgrade') } if ChatwootApp.chatwoot_cloud?

      return { error: I18n.t('captain.disabled') }
    end

    result = super
    increment_usage if successful_result?(result)
    result
  end

  private

  def captain_enabled?
    account.feature_enabled?('captain_integration')
  end

  def responses_available?
    account.usage_limits[:captain][:responses][:current_available].positive?
  end

  def successful_result?(result)
    result.is_a?(Hash) && result[:message].present? && !result[:error]
  end

  def increment_usage
    credits = account.using_openai_hook_key? ? 1 : Llm::Models.credit_multiplier_for(configured_model)
    Rails.logger.info("[CAPTAIN][#{self.class.name}] Incrementing response usage for account #{account.id} by #{credits} credits")
    account.increment_response_usage(credits: credits)
  end
end
