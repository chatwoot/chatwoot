module Enterprise::Captain::BaseTaskService
  def perform
    usage_reservation = reserve_usage
    return { error: I18n.t('captain.copilot_limit'), error_code: 429 } if usage_reservation == false
    return disabled_result(usage_reservation) unless captain_tasks_enabled?

    result = super
    finalize_usage(result, usage_reservation)
    result
  rescue StandardError
    release_usage(usage_reservation) if usage_reservation
    raise
  end

  private

  def reserve_usage
    return unless counts_toward_usage? && ChatwootApp.chatwoot_cloud?
    return false unless responses_available?

    Rails.logger.info("[CAPTAIN][#{self.class.name}] Reserving response usage for account #{account.id}")
    account.reserve_response_usage
  end

  def disabled_result(usage_reservation)
    release_usage(usage_reservation) if usage_reservation
    error_key = ChatwootApp.chatwoot_cloud? ? 'captain.upgrade' : 'captain.disabled'
    { error: I18n.t(error_key) }
  end

  def finalize_usage(result, usage_reservation)
    successful = successful_result?(result)
    return successful ? commit_usage(usage_reservation) : release_usage(usage_reservation) if usage_reservation

    increment_usage if counts_toward_usage? && successful
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

  def release_usage(usage_reservation)
    Rails.logger.info("[CAPTAIN][#{self.class.name}] Releasing response usage for account #{account.id}")
    account.release_response_usage(usage_reservation)
  end

  def commit_usage(usage_reservation)
    Rails.logger.info("[CAPTAIN][#{self.class.name}] Committing response usage for account #{account.id}")
    account.commit_response_usage(usage_reservation)
  end
end
