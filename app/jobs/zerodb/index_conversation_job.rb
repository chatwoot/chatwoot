# frozen_string_literal: true

module Zerodb
  # Background job for indexing conversations in ZeroDB for semantic search
  # Triggered after message creation to keep search index up-to-date
  class IndexConversationJob < ApplicationJob
    queue_as :default

    # Number of retry attempts for failed indexing
    retry_on Zerodb::BaseService::NetworkError, wait: :exponentially_longer, attempts: 3
    retry_on Zerodb::BaseService::RateLimitError, wait: 1.minute, attempts: 5
    discard_on Zerodb::BaseService::AuthenticationError
    discard_on Zerodb::BaseService::ValidationError
    discard_on ActiveRecord::RecordNotFound

    # Index a conversation by ID
    # Fetches the conversation and indexes it using SemanticSearchService
    #
    # @param conversation_id [Integer] The ID of the conversation to index
    # @raise [ActiveRecord::RecordNotFound] if conversation doesn't exist
    def perform(conversation_id)
      Rails.logger.info("[ZeroDB IndexJob] Starting indexing for conversation #{conversation_id}")
      start_time = Time.current

      conversation = Conversation.find(conversation_id)

      # Skip indexing if conversation has no messages
      if conversation.messages.where(message_type: [:incoming, :outgoing]).empty?
        Rails.logger.info("[ZeroDB IndexJob] Skipping conversation #{conversation_id} - no messages")
        return
      end

      # Index conversation using semantic search service
      service = SemanticSearchService.new
      result = service.index_conversation(conversation)

      duration = ((Time.current - start_time) * 1000).round(2)
      Rails.logger.info("[ZeroDB IndexJob] Successfully indexed conversation #{conversation_id} in #{duration}ms")

      result
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error("[ZeroDB IndexJob] Conversation #{conversation_id} not found: #{e.message}")
      raise
    rescue Zerodb::BaseService::AuthenticationError => e
      Rails.logger.error("[ZeroDB IndexJob] Authentication failed for conversation #{conversation_id}: #{e.message}")
      raise
    rescue Zerodb::BaseService::ValidationError => e
      Rails.logger.error("[ZeroDB IndexJob] Validation failed for conversation #{conversation_id}: #{e.message}")
      raise
    rescue StandardError => e
      Rails.logger.error("[ZeroDB IndexJob] Failed to index conversation #{conversation_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    end
  end
end
