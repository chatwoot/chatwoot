module Enterprise::Captain::BaseTaskService
  def perform
    result = super
    increment_usage if successful_result?(result)
    result
  end

  private

  def successful_result?(result)
    result.is_a?(Hash) && result[:message].present? && !result[:error]
  end

  def increment_usage
    Rails.logger.info("[CAPTAIN][#{self.class.name}] Incrementing response usage for account #{account.id}")
    account.increment_response_usage
  end
end
