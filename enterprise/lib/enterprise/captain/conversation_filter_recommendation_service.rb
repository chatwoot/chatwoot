module Enterprise::Captain::ConversationFilterRecommendationService
  def perform
    super
  rescue CustomExceptions::JevQuotaError
    nil
  end
end
