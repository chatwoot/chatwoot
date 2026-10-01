class Api::V1::Accounts::Conversations::SuggestionsController < Api::V1::Accounts::Conversations::BaseController
  FEATURE = 'captain_classifier'.freeze

  before_action :ensure_feature_enabled

  rescue_from CustomExceptions::JevQuotaError do |error|
    response.set_header('Retry-After', error.retry_after.to_s)
    render json: { error: error.code, retry_after: error.retry_after }, status: :too_many_requests
  end

  def labels
    render json: { labels: classifier.labels }
  end

  def priority
    render json: classifier.priority
  end

  private

  def ensure_feature_enabled
    raise Pundit::NotAuthorizedError unless Current.account.feature_enabled?(FEATURE)
  end

  def classifier
    Captain::ConversationClassifierService.new(conversation: @conversation)
  end
end
