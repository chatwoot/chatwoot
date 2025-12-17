# frozen_string_literal: true

class Api::V1::Accounts::Conversations::CannedResponseSuggestionsController < Api::V1::Accounts::Conversations::BaseController
  # GET /api/v1/accounts/:account_id/conversations/:conversation_id/canned_response_suggestions
  # Returns AI-powered canned response suggestions based on conversation context
  def index
    @suggestions = fetch_suggestions
    render json: {
      suggestions: @suggestions,
      meta: {
        count: @suggestions.size,
        conversation_id: @conversation.id,
        powered_by: 'ZeroDB AI'
      }
    }, status: :ok
  rescue Zerodb::BaseService::ZeroDBError => e
    render_zerodb_error(e)
  rescue StandardError => e
    render_server_error(e)
  end

  private

  # Fetch AI-powered suggestions using ZeroDB semantic search
  # @return [Array<Hash>] Array of suggested canned responses with scores
  def fetch_suggestions
    limit = params[:limit]&.to_i || 5
    limit = [limit, 20].min # Cap at 20 suggestions

    suggester = Zerodb::CannedResponseSuggester.new(Current.account.id)
    suggester.suggest(@conversation, limit: limit)
  end

  # Render ZeroDB-specific error with appropriate status
  # @param error [Zerodb::BaseService::ZeroDBError] ZeroDB error
  def render_zerodb_error(error)
    Rails.logger.error("[CannedResponseSuggestions] ZeroDB error: #{error.message}")
    
    status_code = case error
                  when Zerodb::BaseService::AuthenticationError
                    :unauthorized
                  when Zerodb::BaseService::RateLimitError
                    :too_many_requests
                  when Zerodb::BaseService::ValidationError
                    :unprocessable_entity
                  else
                    :service_unavailable
                  end

    render json: {
      error: 'AI suggestions temporarily unavailable',
      message: error.message,
      suggestions: []
    }, status: status_code
  end

  # Render generic server error
  # @param error [StandardError] Server error
  def render_server_error(error)
    Rails.logger.error("[CannedResponseSuggestions] Server error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))

    render json: {
      error: 'Failed to fetch suggestions',
      message: error.message,
      suggestions: []
    }, status: :internal_server_error
  end
end
