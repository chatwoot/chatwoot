# frozen_string_literal: true

module Zerodb
  # Service for indexing canned responses and suggesting them based on conversation context
  # Uses ZeroDB's embed_and_store endpoint for automatic embedding generation and storage
  class CannedResponseSuggester < BaseService
    SIMILARITY_THRESHOLD = 0.6
    DEFAULT_LIMIT = 5

    def initialize(account_id)
      super()
      @account_id = account_id
      @embeddings_client = EmbeddingsClient.new
      @vector_client = VectorClient.new
    end

    # Index a single canned response to ZeroDB using embed_and_store endpoint
    # @param canned_response [CannedResponse] The canned response to index
    # @return [Hash] Response from ZeroDB API
    def index_response(canned_response)
      raise ValidationError, 'Canned response cannot be nil' if canned_response.nil?
      raise ValidationError, 'Canned response must be valid' unless canned_response.valid?

      documents = [
        {
          text: build_document_text(canned_response),
          id: generate_vector_id(canned_response),
          metadata: build_metadata(canned_response)
        }
      ]

      response = @embeddings_client.embed_and_store(
        documents,
        namespace: namespace_for_account
      )

      Rails.logger.info("[CannedResponseSuggester] Indexed canned response #{canned_response.id} to ZeroDB")
      response
    rescue ZeroDBError => e
      Rails.logger.error("[CannedResponseSuggester] Failed to index canned response #{canned_response.id}: #{e.message}")
      raise
    end

    # Remove a canned response from ZeroDB index
    # @param canned_response [CannedResponse, OpenStruct] The canned response to remove
    # @return [Hash] Response from ZeroDB API
    def delete_response(canned_response)
      raise ValidationError, 'Canned response cannot be nil' if canned_response.nil?
      raise ValidationError, 'Canned response must have an ID' if canned_response.id.blank?

      vector_id = generate_vector_id(canned_response)

      response = @vector_client.delete_vector(
        vector_id,
        namespace: namespace_for_account
      )

      Rails.logger.info("[CannedResponseSuggester] Deleted canned response #{canned_response.id} from ZeroDB")
      response
    rescue ZeroDBError => e
      Rails.logger.error("[CannedResponseSuggester] Failed to delete canned response #{canned_response.id}: #{e.message}")
      raise
    end

    # Suggest canned responses based on conversation context
    # @param conversation [Conversation] The conversation to suggest responses for
    # @param limit [Integer] Maximum number of suggestions to return
    # @return [Array<CannedResponse>] Array of CannedResponse AR objects sorted by similarity
    def suggest(conversation, limit: DEFAULT_LIMIT)
      raise ValidationError, 'Conversation cannot be nil' if conversation.nil?
      raise ValidationError, 'Limit must be positive' unless limit.positive?

      # Get conversation context from last 3 customer messages
      context = extract_conversation_context(conversation)
      return [] if context.blank?

      # Generate embedding for the conversation context
      embedding_response = @embeddings_client.generate_embedding(context)
      query_vector = embedding_response['embedding']

      # Search for similar canned responses
      search_results = @vector_client.search_vectors(
        query_vector,
        limit,
        namespace: namespace_for_account,
        threshold: SIMILARITY_THRESHOLD,
        filters: { account_id: @account_id }
      )

      # Convert search results to CannedResponse AR objects
      hydrate_canned_responses(search_results)
    rescue ZeroDBError => e
      Rails.logger.error("[CannedResponseSuggester] Failed to suggest responses for conversation #{conversation.id}: #{e.message}")
      []
    end

    # Reindex all canned responses for the account
    # @return [Hash] Summary of indexing results
    def reindex_all
      canned_responses = CannedResponse.where(account_id: @account_id)
      results = { total: canned_responses.count, indexed: 0, failed: 0, errors: [] }

      canned_responses.find_each do |response|
        index_response(response)
        results[:indexed] += 1
      rescue StandardError => e
        results[:failed] += 1
        results[:errors] << { id: response.id, error: e.message }
      end

      Rails.logger.info("[CannedResponseSuggester] Reindexed #{results[:indexed]}/#{results[:total]} canned responses")
      results
    end

    private

    attr_reader :account_id, :embeddings_client, :vector_client

    # Generate namespace for account-specific canned responses
    # @return [String] Namespace identifier
    def namespace_for_account
      "canned_responses_#{@account_id}"
    end

    # Generate unique vector ID for a canned response
    # @param canned_response [CannedResponse, OpenStruct] The canned response
    # @return [String] Unique vector ID
    def generate_vector_id(canned_response)
      "canned_response_#{canned_response.account_id}_#{canned_response.id}"
    end

    # Build searchable document text from canned response
    # Combines short_code and content for better semantic matching
    # @param canned_response [CannedResponse] The canned response
    # @return [String] Document text for embedding
    def build_document_text(canned_response)
      "#{canned_response.short_code}: #{canned_response.content}"
    end

    # Build metadata for vector storage
    # @param canned_response [CannedResponse] The canned response
    # @return [Hash] Metadata hash
    def build_metadata(canned_response)
      {
        canned_response_id: canned_response.id,
        account_id: canned_response.account_id,
        short_code: canned_response.short_code,
        content: canned_response.content,
        created_at: canned_response.created_at.iso8601,
        updated_at: canned_response.updated_at.iso8601
      }
    end

    # Extract conversation context from last customer messages
    # @param conversation [Conversation] The conversation
    # @return [String] Context text for searching
    def extract_conversation_context(conversation)
      # Get last 3 customer messages (incoming messages)
      messages = conversation.messages
                           .where(message_type: :incoming)
                           .order(created_at: :desc)
                           .limit(3)
                           .pluck(:content)

      # Return messages in chronological order (oldest first)
      messages.reverse.join(' ')
    end

    # Convert ZeroDB search results to CannedResponse ActiveRecord objects
    # @param search_results [Hash] Raw search results from ZeroDB
    # @return [Array<CannedResponse>] Array of CannedResponse objects sorted by similarity
    def hydrate_canned_responses(search_results)
      results = search_results['results'] || []
      return [] if results.empty?

      # Extract canned response IDs from metadata
      canned_response_ids = results.map do |result|
        result.dig('metadata', 'canned_response_id')
      end.compact

      return [] if canned_response_ids.empty?

      # Fetch CannedResponse objects and maintain order from search results
      canned_responses = CannedResponse.where(id: canned_response_ids, account_id: @account_id)
                                      .index_by(&:id)

      # Return in order of similarity score
      results.map do |result|
        canned_responses[result.dig('metadata', 'canned_response_id')]
      end.compact
    end
  end
end
