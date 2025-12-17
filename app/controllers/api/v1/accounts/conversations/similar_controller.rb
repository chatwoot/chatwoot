# frozen_string_literal: true

class Api::V1::Accounts::Conversations::SimilarController < Api::V1::Accounts::Conversations::BaseController
  # GET /api/v1/accounts/:account_id/conversations/:conversation_id/similar
  # Returns similar conversations based on semantic similarity of content
  #
  # Query Parameters:
  #   - limit: Maximum number of similar tickets to return (default: 5, max: 20)
  #   - threshold: Similarity threshold 0.0-1.0 (default: 0.75)
  #   - exclude_statuses: Comma-separated list of statuses to exclude
  #
  # Response:
  #   {
  #     "data": [
  #       {
  #         "conversation": { ... },
  #         "similarity_score": 0.89
  #       }
  #     ],
  #     "meta": {
  #       "count": 3,
  #       "threshold": 0.75,
  #       "query_conversation_id": 123
  #     }
  #   }
  def index
    begin
      # Validate and sanitize parameters
      limit = validate_limit_param
      threshold = validate_threshold_param
      exclude_statuses = parse_exclude_statuses

      # Find similar tickets using ZeroDB service
      similar_service = Zerodb::SimilarTicketDetector.new
      similar_results = similar_service.find_similar(
        @conversation,
        limit: limit,
        threshold: threshold,
        exclude_statuses: exclude_statuses
      )

      # Format response
      render json: {
        data: format_similar_results(similar_results),
        meta: {
          count: similar_results.size,
          threshold: threshold,
          query_conversation_id: @conversation.id,
          account_id: Current.account.id
        }
      }, status: :ok

    rescue Zerodb::BaseService::ValidationError => e
      render json: {
        error: 'Validation Error',
        message: e.message
      }, status: :unprocessable_entity

    rescue Zerodb::BaseService::ConfigurationError => e
      Rails.logger.error("[SimilarController] Configuration error: #{e.message}")
      render json: {
        error: 'Service Configuration Error',
        message: 'Similar ticket detection is not properly configured'
      }, status: :service_unavailable

    rescue Zerodb::SimilarTicketDetector::SimilarityDetectionError => e
      Rails.logger.error("[SimilarController] Detection failed: #{e.message}")
      render json: {
        error: 'Detection Failed',
        message: 'Failed to find similar tickets. Please try again later.'
      }, status: :internal_server_error

    rescue StandardError => e
      Rails.logger.error("[SimilarController] Unexpected error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: {
        error: 'Internal Server Error',
        message: 'An unexpected error occurred'
      }, status: :internal_server_error
    end
  end

  private

  # Validate and return limit parameter
  # @return [Integer] Validated limit value
  def validate_limit_param
    limit = params[:limit].to_i
    limit = Zerodb::SimilarTicketDetector::DEFAULT_LIMIT if limit.zero?

    if limit > Zerodb::SimilarTicketDetector::MAX_LIMIT
      limit = Zerodb::SimilarTicketDetector::MAX_LIMIT
      Rails.logger.warn("[SimilarController] Limit capped at #{Zerodb::SimilarTicketDetector::MAX_LIMIT}")
    end

    limit
  end

  # Validate and return threshold parameter
  # @return [Float] Validated threshold value
  def validate_threshold_param
    threshold = params[:threshold].to_f

    # Use default if not provided or invalid
    return Zerodb::SimilarTicketDetector::DEFAULT_SIMILARITY_THRESHOLD if threshold.zero?

    # Clamp to valid range [0.0, 1.0]
    threshold = [[threshold, 0.0].max, 1.0].min

    threshold
  end

  # Parse exclude_statuses parameter
  # @return [Array<String>] Array of status strings to exclude
  def parse_exclude_statuses
    return [] unless params[:exclude_statuses].present?

    statuses = params[:exclude_statuses].to_s.split(',').map(&:strip).map(&:downcase)

    # Validate against known statuses
    valid_statuses = Conversation.statuses.keys
    statuses.select { |status| valid_statuses.include?(status) }
  end

  # Format similar results for API response
  # @param results [Array<Hash>] Results from SimilarTicketDetector
  # @return [Array<Hash>] Formatted results
  def format_similar_results(results)
    results.map do |result|
      {
        conversation: format_conversation(result[:conversation]),
        similarity_score: format_similarity_score(result[:similarity_score])
      }
    end
  end

  # Format conversation data for API response
  # Uses existing Chatwoot conversation serializer pattern
  # @param conversation [Conversation] Conversation object
  # @return [Hash] Formatted conversation data
  def format_conversation(conversation)
    {
      id: conversation.id,
      display_id: conversation.display_id,
      inbox_id: conversation.inbox_id,
      status: conversation.status,
      created_at: conversation.created_at,
      updated_at: conversation.updated_at,
      last_activity_at: conversation.last_activity_at,
      contact: format_contact(conversation.contact),
      assignee: format_assignee(conversation.assignee),
      messages_count: conversation.messages.count,
      unread_count: conversation.unread_incoming_messages.count,
      additional_attributes: conversation.additional_attributes,
      custom_attributes: conversation.custom_attributes,
      labels: conversation.label_list
    }
  end

  # Format contact data
  # @param contact [Contact] Contact object
  # @return [Hash] Formatted contact data
  def format_contact(contact)
    return nil unless contact

    {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number,
      thumbnail: contact.avatar_url
    }
  end

  # Format assignee data
  # @param assignee [User] Assignee object
  # @return [Hash] Formatted assignee data
  def format_assignee(assignee)
    return nil unless assignee

    {
      id: assignee.id,
      name: assignee.name,
      email: assignee.email,
      thumbnail: assignee.avatar_url
    }
  end

  # Format similarity score as percentage
  # @param score [Float] Raw similarity score (0.0-1.0)
  # @return [Float] Formatted score with 2 decimal places
  def format_similarity_score(score)
    return 0.0 unless score

    (score * 100).round(2)
  end
end
