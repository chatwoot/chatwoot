# frozen_string_literal: true

class Api::V1::Accounts::Conversations::SemanticSearchController < Api::V1::Accounts::Conversations::BaseController
  skip_before_action :set_conversation
  before_action :check_authorization

  # POST /api/v1/accounts/:account_id/conversations/semantic_search
  # Performs semantic search on conversations using ZeroDB vector embeddings
  #
  # Request Body:
  #   {
  #     "query": "customer asking about refund policy",
  #     "limit": 20,
  #     "status": "open",
  #     "inbox_id": 123
  #   }
  #
  # Response:
  #   {
  #     "data": [
  #       { "id": 123, "display_id": 456, ... }
  #     ],
  #     "meta": {
  #       "total_count": 5,
  #       "query": "customer asking about refund policy",
  #       "limit": 20
  #     }
  #   }
  def create
    validate_search_params!

    # Execute semantic search using ZeroDB service
    conversations = Zerodb::SemanticSearchService.new
                                                  .search(
                                                    search_params[:query],
                                                    limit: validated_limit,
                                                    filters: build_filters
                                                  )

    # Render response with conversation data
    render json: {
      data: format_conversations(conversations),
      meta: {
        total_count: conversations.size,
        query: search_params[:query],
        limit: validated_limit,
        account_id: Current.account.id
      }
    }, status: :ok

  rescue Zerodb::SemanticSearchService::SearchError => e
    Rails.logger.error("[SemanticSearchController] Search failed: #{e.message}")
    render json: {
      error: 'Search Failed',
      message: 'Semantic search service encountered an error. Please try again later.'
    }, status: :internal_server_error

  rescue Zerodb::BaseService::NetworkError => e
    Rails.logger.error("[SemanticSearchController] Network error: #{e.message}")
    render json: {
      error: 'Service Unavailable',
      message: 'Search service is temporarily unavailable. Please try again later.'
    }, status: :service_unavailable

  rescue Zerodb::BaseService::RateLimitError => e
    Rails.logger.warn("[SemanticSearchController] Rate limit exceeded: #{e.message}")
    render json: {
      error: 'Rate Limit Exceeded',
      message: 'Too many search requests. Please try again later.'
    }, status: :too_many_requests

  rescue Zerodb::BaseService::AuthenticationError => e
    Rails.logger.error("[SemanticSearchController] Auth error: #{e.message}")
    render json: {
      error: 'Service Configuration Error',
      message: 'Search service authentication failed. Please contact support.'
    }, status: :service_unavailable

  rescue Zerodb::BaseService::ValidationError => e
    render json: {
      error: 'Validation Error',
      message: e.message
    }, status: :unprocessable_entity

  rescue StandardError => e
    Rails.logger.error("[SemanticSearchController] Unexpected error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: {
      error: 'Internal Server Error',
      message: 'An unexpected error occurred while processing your search.'
    }, status: :internal_server_error
  end

  private

  # Validate that required search parameters are present
  # @raise [ActionController::ParameterMissing] if query is missing
  def validate_search_params!
    if search_params[:query].blank?
      raise ActionController::ParameterMissing, 'query parameter is required'
    end
  end

  # Permitted search parameters
  # @return [ActionController::Parameters] Permitted params
  def search_params
    params.permit(:query, :limit, :status, :inbox_id, :assignee_id)
  end

  # Validate and return limit parameter with bounds checking
  # @return [Integer] Validated limit value (1-100)
  def validated_limit
    limit = search_params[:limit].to_i
    limit = 20 if limit.zero? # Default limit
    limit = [[limit, 1].max, 100].min # Clamp between 1 and 100
    limit
  end

  # Build metadata filters for ZeroDB search
  # Ensures account isolation and applies optional filters
  # @return [Hash] Filter hash with account_id and optional status, inbox_id
  def build_filters
    filters = { account_id: Current.account.id }

    # Add optional filters if provided
    filters[:status] = search_params[:status] if search_params[:status].present?
    filters[:inbox_id] = search_params[:inbox_id].to_i if search_params[:inbox_id].present?
    filters[:assignee_id] = search_params[:assignee_id].to_i if search_params[:assignee_id].present?

    filters
  end

  # Format conversations for API response
  # @param conversations [Array<Conversation>] Conversation ActiveRecord objects
  # @return [Array<Hash>] Formatted conversation data
  def format_conversations(conversations)
    conversations.map do |conversation|
      format_conversation(conversation)
    end
  end

  # Format single conversation for API response
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
      labels: conversation.label_list,
      priority: conversation.priority
    }
  end

  # Format contact data for API response
  # @param contact [Contact] Contact object
  # @return [Hash, nil] Formatted contact data or nil
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

  # Format assignee data for API response
  # @param assignee [User] Assignee object
  # @return [Hash, nil] Formatted assignee data or nil
  def format_assignee(assignee)
    return nil unless assignee

    {
      id: assignee.id,
      name: assignee.name,
      email: assignee.email,
      thumbnail: assignee.avatar_url
    }
  end

  # Check if user is authorized to search conversations
  # Uses existing Chatwoot authorization pattern
  def check_authorization
    authorize(Conversation.new(account: Current.account))
  end
end
