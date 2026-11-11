module Enterprise::Captain::FilterRecommendationService
  def perform
    super
  rescue CustomExceptions::JevQuotaError
    nil
  end
end
