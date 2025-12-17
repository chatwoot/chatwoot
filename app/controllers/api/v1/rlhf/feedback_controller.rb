# frozen_string_literal: true

# RLHF Feedback Controller
# Handles collection of agent feedback on AI suggestions for continuous improvement
#
# Endpoints:
# - POST /api/v1/rlhf/feedback - Submit feedback on AI suggestion
# - GET  /api/v1/rlhf/stats    - Get RLHF statistics for current account
class Api::V1::Rlhf::FeedbackController < Api::V1::Accounts::BaseController
  before_action :validate_feedback_params, only: [:create]

  # POST /api/v1/rlhf/feedback
  # Submit feedback on AI-generated suggestion
  #
  # Parameters:
  # - suggestion_type: Type of suggestion (required)
  # - prompt: Original user input/context (required)
  # - response: AI-generated suggestion (required)
  # - rating: Rating 1-5, or use thumbs: 'up'/'down' (required if thumbs not provided)
  # - thumbs: 'up' or 'down' (required if rating not provided)
  # - feedback: Optional text feedback
  # - metadata: Optional additional context (conversation_id, suggestion_id, etc.)
  #
  # @example Success Response
  #   {
  #     "message": "Feedback recorded successfully",
  #     "feedback_id": "abc123"
  #   }
  def create
    service = Zerodb::RlhfService.new(account_id: Current.account.id)

    rating = determine_rating
    result = service.log_feedback(
      suggestion_type: params[:suggestion_type],
      prompt: params[:prompt],
      response: params[:response],
      rating: rating,
      feedback: params[:feedback],
      metadata: build_metadata
    )

    render json: {
      message: 'Feedback recorded successfully',
      feedback_id: result['id'] || result['feedback_id']
    }, status: :created
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("RLHF feedback submission failed: #{e.message}")
    render json: { error: 'Failed to record feedback' }, status: :internal_server_error
  end

  # GET /api/v1/rlhf/stats
  # Get RLHF statistics for current account
  #
  # @example Success Response
  #   {
  #     "total_feedback": 150,
  #     "avg_rating": 4.2,
  #     "feedback_by_type": {
  #       "canned_response_suggestion": 80,
  #       "semantic_search": 70
  #     },
  #     "recent_feedback": [...]
  #   }
  def stats
    service = Zerodb::RlhfService.new(account_id: Current.account.id)
    result = service.get_stats

    render json: result, status: :ok
  rescue StandardError => e
    Rails.logger.error("RLHF stats retrieval failed: #{e.message}")
    render json: { error: 'Failed to retrieve statistics' }, status: :internal_server_error
  end

  private

  # Validate required feedback parameters
  def validate_feedback_params
    required_params = [:suggestion_type, :prompt, :response]
    missing_params = required_params.select { |param| params[param].blank? }

    if missing_params.any?
      render json: {
        error: 'Missing required parameters',
        missing: missing_params
      }, status: :bad_request
      return
    end

    # Ensure either rating or thumbs is provided
    return if params[:rating].present? || params[:thumbs].present?

    render json: {
      error: 'Either rating (1-5) or thumbs (up/down) must be provided'
    }, status: :bad_request
  end

  # Determine rating from params (either direct rating or converted from thumbs)
  # @return [Integer] Rating value 1-5
  def determine_rating
    if params[:rating].present?
      params[:rating].to_i
    elsif params[:thumbs].present?
      Zerodb::RlhfService.thumbs_to_rating(params[:thumbs])
    else
      raise ArgumentError, 'Either rating or thumbs must be provided'
    end
  end

  # Build metadata hash with additional context
  # @return [Hash] Metadata including conversation_id, agent_id, etc.
  def build_metadata
    metadata = params[:metadata]&.to_unsafe_h || {}

    # Add standard metadata
    metadata.merge!(
      agent_id: current_user.id,
      agent_name: current_user.name,
      account_id: Current.account.id,
      timestamp: Time.current.iso8601
    )

    # Add conversation context if present
    if params[:conversation_id].present?
      metadata[:conversation_id] = params[:conversation_id]
    end

    # Add suggestion ID if present
    if params[:suggestion_id].present?
      metadata[:suggestion_id] = params[:suggestion_id]
    end

    metadata
  end
end
