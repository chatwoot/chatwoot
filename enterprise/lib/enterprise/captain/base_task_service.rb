module Enterprise::Captain::BaseTaskService
  def perform
    usage_reserved = reserve_usage
    return { error: I18n.t('captain.copilot_limit'), error_code: 429 } if usage_reserved == false
    return disabled_result(usage_reserved) unless captain_tasks_enabled?

    result = super
    finalize_usage(result, usage_reserved)
    result
  rescue StandardError
    release_usage if usage_reserved
    raise
  end

  private

  def reserve_usage
    return unless counts_toward_usage? && ChatwootApp.chatwoot_cloud?
    return false unless responses_available?

    Rails.logger.info("[CAPTAIN][#{self.class.name}] Reserving response usage for account #{account.id}")
    account.reserve_response_usage
  end

  def disabled_result(usage_reserved)
    release_usage if usage_reserved
    error_key = ChatwootApp.chatwoot_cloud? ? 'captain.upgrade' : 'captain.disabled'
    { error: I18n.t(error_key) }
  end

  def finalize_usage(result, usage_reserved)
    successful = successful_result?(result)
    return release_usage if usage_reserved && !successful
    return increment_usage if usage_reserved.nil? && counts_toward_usage? && successful
  end

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

  def release_usage
    Rails.logger.info("[CAPTAIN][#{self.class.name}] Releasing response usage for account #{account.id}")
    account.release_response_usage
  end
end
