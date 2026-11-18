module Enterprise::Captain::AutomationConditionService
  def perform
    super
  rescue CustomExceptions::JevQuotaError
    unmet
  end
end
