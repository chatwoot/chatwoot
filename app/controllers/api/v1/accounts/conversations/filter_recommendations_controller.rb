class Api::V1::Accounts::Conversations::FilterRecommendationsController < Api::V1::Accounts::BaseController
  QUERY_LENGTH = (3..200)

  before_action :ensure_recommendations_available

  def create
    query = params.require(:query).to_s.strip
    return render_could_not_create_error('Query must be between 3 and 200 characters') unless QUERY_LENGTH.cover?(query.length)

    recommendations = Captain::ConversationFilterRecommendationService.new(
      account: Current.account, user: Current.user, query: query
    ).perform
    render json: { payload: recommendations }
  end

  private

  def ensure_recommendations_available
    raise Pundit::NotAuthorizedError unless recommendations_available?
  end

  # Recommendations are a paid feature. Enterprise decides which accounts are on a paid plan.
  def recommendations_available?
    false
  end
end

Api::V1::Accounts::Conversations::FilterRecommendationsController.prepend_mod_with(
  'Api::V1::Accounts::Conversations::FilterRecommendationsController'
)
