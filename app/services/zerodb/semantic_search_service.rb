# frozen_string_literal: true

module Zerodb
  # Service for semantic search of conversations using ZeroDB vector embeddings
  # Indexes conversation messages as vector embeddings and provides semantic search capabilities
  class SemanticSearchService < BaseService
    # Maximum number of messages to include in conversation embedding
    MAX_MESSAGES_FOR_EMBEDDING = 20
    # Default dimension for OpenAI text-embedding-3-small
    EMBEDDING_DIMENSION = 1536
    # Default similarity threshold for search results
    DEFAULT_SIMILARITY_THRESHOLD = 0.7

    # Custom error classes
    class EmbeddingGenerationError < ZeroDBError; end
    class IndexingError < ZeroDBError; end
    class SearchError < ZeroDBError; end

    # Index a conversation in ZeroDB for semantic search
    # Generates embedding from conversation messages and stores with metadata
    #
    # @param conversation [Conversation] The conversation to index
    # @return [Hash] Response from ZeroDB containing vector_id and metadata
    # @raise [IndexingError] if indexing fails
    # @raise [ValidationError] if conversation is invalid
    def index_conversation(conversation)
      raise ValidationError, 'Conversation cannot be nil' if conversation.nil?
      raise ValidationError, 'Conversation must be persisted' unless conversation.persisted?

      Rails.logger.info("[ZeroDB SemanticSearch] Indexing conversation #{conversation.id}")

      # Generate text content from conversation messages
      text_content = generate_conversation_text(conversation)
      raise IndexingError, 'Conversation has no indexable content' if text_content.blank?

      # Generate embedding using OpenAI API
      embedding = generate_embedding(text_content)

      # Prepare metadata for filtering and retrieval
      metadata = build_conversation_metadata(conversation)

      # Store vector embedding in ZeroDB
      response = upsert_vector(
        vector_id: vector_id_for_conversation(conversation),
        embedding: embedding,
        document: text_content.truncate(1000), # Store preview for context
        metadata: metadata
      )

      Rails.logger.info("[ZeroDB SemanticSearch] Successfully indexed conversation #{conversation.id}")
      response
    rescue StandardError => e
      Rails.logger.error("[ZeroDB SemanticSearch] Failed to index conversation #{conversation.id}: #{e.message}")
      raise IndexingError, "Failed to index conversation: #{e.message}"
    end

    # Search for conversations semantically similar to query
    # Returns ActiveRecord Conversation objects ordered by relevance
    #
    # @param query [String] The search query text
    # @param limit [Integer] Maximum number of results to return (default: 10)
    # @param filters [Hash] Optional filters for account_id, status, etc.
    # @option filters [Integer] :account_id Account ID for multi-tenancy isolation
    # @option filters [String] :status Conversation status filter
    # @option filters [Integer] :inbox_id Inbox ID filter
    # @option filters [Float] :threshold Similarity threshold (default: 0.7)
    # @return [Array<Conversation>] Array of Conversation ActiveRecord objects
    # @raise [SearchError] if search fails
    # @raise [ValidationError] if query is invalid
    def search(query, limit: 10, filters: {})
      raise ValidationError, 'Query cannot be blank' if query.blank?
      raise ValidationError, 'Limit must be between 1 and 100' unless limit.between?(1, 100)
      raise ValidationError, 'Account ID is required for search' if filters[:account_id].blank?

      start_time = Time.current
      Rails.logger.info("[ZeroDB SemanticSearch] Searching for: #{query.truncate(50)}")

      # Generate embedding for search query
      query_embedding = generate_embedding(query)

      # Build metadata filters for ZeroDB
      metadata_filters = build_search_filters(filters)
      threshold = filters[:threshold] || DEFAULT_SIMILARITY_THRESHOLD

      # Search vectors in ZeroDB
      search_response = search_vectors(
        query_vector: query_embedding,
        limit: limit,
        metadata_filters: metadata_filters,
        threshold: threshold
      )

      # Extract conversation IDs from search results
      conversation_ids = extract_conversation_ids(search_response)

      # Fetch Conversation AR objects preserving search order
      conversations = fetch_conversations_by_ids(conversation_ids, filters[:account_id])

      duration = ((Time.current - start_time) * 1000).round(2)
      Rails.logger.info("[ZeroDB SemanticSearch] Found #{conversations.size} conversations in #{duration}ms")

      conversations
    rescue StandardError => e
      Rails.logger.error("[ZeroDB SemanticSearch] Search failed: #{e.message}")
      raise SearchError, "Search failed: #{e.message}"
    end

    # Delete a conversation's vector from ZeroDB
    #
    # @param conversation [Conversation] The conversation to remove from index
    # @return [Boolean] true if deletion was successful
    def delete_conversation(conversation)
      raise ValidationError, 'Conversation cannot be nil' if conversation.nil?

      vector_id = vector_id_for_conversation(conversation)
      delete_vector(vector_id: vector_id)

      Rails.logger.info("[ZeroDB SemanticSearch] Deleted conversation #{conversation.id} from index")
      true
    rescue StandardError => e
      Rails.logger.warn("[ZeroDB SemanticSearch] Failed to delete conversation #{conversation.id}: #{e.message}")
      false
    end

    private

    # Generate combined text content from conversation messages
    # @param conversation [Conversation] The conversation
    # @return [String] Combined message content
    def generate_conversation_text(conversation)
      messages = conversation.messages
                             .where(message_type: [:incoming, :outgoing])
                             .where.not(content: [nil, ''])
                             .order(created_at: :desc)
                             .limit(MAX_MESSAGES_FOR_EMBEDDING)

      return '' if messages.empty?

      # Combine messages with role labels for better context
      messages.reverse.map do |msg|
        role = msg.incoming? ? 'Customer' : 'Agent'
        "#{role}: #{msg.content}"
      end.join("\n\n")
    end

    # Build metadata hash for conversation
    # @param conversation [Conversation] The conversation
    # @return [Hash] Metadata for filtering and retrieval
    def build_conversation_metadata(conversation)
      {
        conversation_id: conversation.id,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        status: conversation.status,
        contact_id: conversation.contact_id,
        assignee_id: conversation.assignee_id,
        created_at: conversation.created_at.iso8601,
        updated_at: conversation.updated_at.iso8601,
        message_count: conversation.messages.count
      }
    end

    # Generate unique vector ID for conversation
    # @param conversation [Conversation] The conversation
    # @return [String] Unique vector identifier
    def vector_id_for_conversation(conversation)
      "conversation_#{conversation.account_id}_#{conversation.id}"
    end

    # Build metadata filters for ZeroDB search
    # @param filters [Hash] Filter parameters
    # @return [Hash] Metadata filters for ZeroDB
    def build_search_filters(filters)
      metadata = { account_id: filters[:account_id] }
      metadata[:status] = filters[:status] if filters[:status].present?
      metadata[:inbox_id] = filters[:inbox_id] if filters[:inbox_id].present?
      metadata[:assignee_id] = filters[:assignee_id] if filters[:assignee_id].present?
      metadata
    end

    # Extract conversation IDs from ZeroDB search response
    # @param response [Hash] ZeroDB search response
    # @return [Array<Integer>] Ordered array of conversation IDs
    def extract_conversation_ids(response)
      return [] unless response && response['results']

      response['results'].map do |result|
        result.dig('metadata', 'conversation_id')
      end.compact
    end

    # Fetch conversations by IDs preserving search order
    # @param conversation_ids [Array<Integer>] Ordered conversation IDs
    # @param account_id [Integer] Account ID for authorization
    # @return [Array<Conversation>] Ordered conversation objects
    def fetch_conversations_by_ids(conversation_ids, account_id)
      return [] if conversation_ids.empty?

      # Fetch all conversations in single query
      conversations = Conversation.where(id: conversation_ids, account_id: account_id)
                                  .includes(:contact, :inbox, :assignee)
                                  .index_by(&:id)

      # Preserve search result order
      conversation_ids.filter_map { |id| conversations[id] }
    end

    # Generate vector embedding using OpenAI API
    # @param text [String] Text to embed
    # @return [Array<Float>] Vector embedding (1536 dimensions)
    # @raise [EmbeddingGenerationError] if embedding generation fails
    def generate_embedding(text)
      raise EmbeddingGenerationError, 'Text cannot be blank' if text.blank?

      # Use OpenAI API for embedding generation
      openai_client = OpenAI::Client.new(access_token: openai_api_key)

      response = openai_client.embeddings(
        parameters: {
          model: 'text-embedding-3-small',
          input: text.truncate(8000) # OpenAI input limit
        }
      )

      embedding = response.dig('data', 0, 'embedding')
      raise EmbeddingGenerationError, 'Failed to generate embedding' if embedding.blank?
      raise EmbeddingGenerationError, "Invalid embedding dimension: #{embedding.size}" if embedding.size != EMBEDDING_DIMENSION

      embedding
    rescue StandardError => e
      Rails.logger.error("[ZeroDB SemanticSearch] Embedding generation failed: #{e.message}")
      raise EmbeddingGenerationError, "Failed to generate embedding: #{e.message}"
    end

    # Upsert vector to ZeroDB
    # @param vector_id [String] Unique vector identifier
    # @param embedding [Array<Float>] Vector embedding
    # @param document [String] Source document text
    # @param metadata [Hash] Metadata for filtering
    # @return [Hash] ZeroDB response
    def upsert_vector(vector_id:, embedding:, document:, metadata:)
      path = api_path('/vectors/upsert')
      body = {
        vector_id: vector_id,
        vector_embedding: embedding,
        document: document,
        metadata: metadata,
        namespace: 'conversations'
      }

      make_request(:post, path, body: body.to_json)
    end

    # Search vectors in ZeroDB
    # @param query_vector [Array<Float>] Query embedding
    # @param limit [Integer] Maximum results
    # @param metadata_filters [Hash] Metadata filters
    # @param threshold [Float] Similarity threshold
    # @return [Hash] Search results
    def search_vectors(query_vector:, limit:, metadata_filters:, threshold:)
      path = api_path('/vectors/search')
      body = {
        query_vector: query_vector,
        limit: limit,
        filter_metadata: metadata_filters,
        threshold: threshold,
        namespace: 'conversations'
      }

      make_request(:post, path, body: body.to_json)
    end

    # Delete vector from ZeroDB
    # @param vector_id [String] Vector identifier
    # @return [Hash] Deletion response
    def delete_vector(vector_id:)
      path = api_path('/vectors/delete')
      body = { vector_id: vector_id, namespace: 'conversations' }

      make_request(:post, path, body: body.to_json)
    end

    # Get OpenAI API key from environment
    # @return [String] OpenAI API key
    # @raise [ConfigurationError] if API key is missing
    def openai_api_key
      key = ENV.fetch('OPENAI_API_KEY', nil)
      raise ConfigurationError, 'OPENAI_API_KEY environment variable is not set' if key.blank?

      key
    end
  end
end
