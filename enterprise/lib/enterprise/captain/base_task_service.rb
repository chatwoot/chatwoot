module Enterprise::Captain::BaseTaskService
  def perform
    return { error: I18n.t('captain.copilot_limit'), error_code: 429 } unless responses_available?

    result = super
    increment_usage if successful_result?(result)
    result
  end

  private

  def responses_available?
    account.usage_limits[:captain][:responses][:current_available].positive?
  end

  def successful_result?(result)
    result.is_a?(Hash) && result[:message].present? && !result[:error]
  end

  def increment_usage
    Rails.logger.info("[CAPTAIN][#{self.class.name}] Incrementing response usage for account #{account.id}")
    account.increment_response_usage
  end
end
