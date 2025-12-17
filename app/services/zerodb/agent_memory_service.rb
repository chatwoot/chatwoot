# frozen_string_literal: true

module Zerodb
  # Service for managing agent memories using ZeroDB Memory API
  # Stores and retrieves customer preferences, notes, and context for agents
  class AgentMemoryService < BaseService
    VALID_IMPORTANCE_LEVELS = %w[low medium high].freeze

    # Initialize service with account scope
    # @param account_id [Integer] Account ID for multi-tenant isolation
    def initialize(account_id)
      super()
      @account_id = account_id
    end

    # Store a memory for a contact
    # @param contact_id [Integer] Contact ID
    # @param content [String] Memory content
    # @param importance [String] Importance level (low, medium, high) - defaults to 'medium'
    # @param tags [Array<String>] Memory tags for categorization - defaults to empty array
    # @return [Hash] API response with stored memory details
    # @raise [ArgumentError] If importance is invalid or content is blank
    def store_memory(contact_id, content, importance: 'medium', tags: [])
      validate_importance!(importance)
      validate_content!(content)

      payload = {
        content: content,
        metadata: {
          contact_id: contact_id,
          account_id: @account_id,
          importance: importance,
          stored_at: Time.current.iso8601
        },
        tags: tags
      }

      make_request(:post, api_path('/database/memory'), body: payload.to_json)
    end

    # Retrieve memories for a contact with optional semantic search
    # @param contact_id [Integer] Contact ID
    # @param query [String, nil] Optional semantic search query
    # @param limit [Integer] Maximum number of memories to return (default: 10)
    # @return [Array<Hash>] Array of memory objects
    def recall_memories(contact_id, query: nil, limit: 10)
      if query.present?
        # Semantic search with query
        payload = {
          query: query,
          limit: limit,
          filter_metadata: {
            contact_id: contact_id,
            account_id: @account_id
          }
        }
        result = make_request(:post, api_path('/database/memory/search'), body: payload.to_json)
        result['results'] || result['memories'] || []
      else
        # List all memories for contact
        query_params = {
          contact_id: contact_id,
          account_id: @account_id,
          limit: limit
        }
        result = make_request(:get, api_path('/database/memory'), query: query_params)
        result['memories'] || result['results'] || []
      end
    end

    private

    # Validate importance level
    # @raise [ArgumentError] If importance is not valid
    def validate_importance!(importance)
      return if VALID_IMPORTANCE_LEVELS.include?(importance)

      raise ArgumentError, "Invalid importance level: #{importance}. Must be one of: #{VALID_IMPORTANCE_LEVELS.join(', ')}"
    end

    # Validate memory content
    # @raise [ArgumentError] If content is blank or too long
    def validate_content!(content)
      raise ArgumentError, 'Memory content cannot be blank' if content.blank?
      raise ArgumentError, 'Memory content is too long (max 5000 characters)' if content.length > 5000
    end
  end
end
