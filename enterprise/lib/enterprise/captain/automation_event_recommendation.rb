module Enterprise::Captain::AutomationEventRecommendation
  def perform
    super
  rescue CustomExceptions::JevQuotaError
    nil
  end
end
