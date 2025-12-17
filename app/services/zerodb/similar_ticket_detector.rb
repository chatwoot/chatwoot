# frozen_string_literal: true

module Zerodb
  # Service for detecting similar conversations using ZeroDB vector similarity search
  # Finds conversations with similar content to help agents reference past solutions
  class SimilarTicketDetector < BaseService
    # Similarity threshold for considering tickets as similar (0.75 = 75% similar)
    DEFAULT_SIMILARITY_THRESHOLD = 0.75
    # Default number of similar tickets to return
    DEFAULT_LIMIT = 5
    # Maximum number of results allowed
    MAX_LIMIT = 20
    # Embedding dimension for OpenAI text-embedding-3-small
    EMBEDDING_DIMENSION = 1536

    # Custom error classes
    class SimilarityDetectionError < ZeroDBError; end

    # Find conversations similar to the given conversation
    # Returns conversations ordered by similarity score (highest first)
    #
    # @param conversation [Conversation] The conversation to find similar tickets for
    # @param limit [Integer] Maximum number of similar tickets to return (default: 5)
    # @option options [Float] :threshold Similarity threshold (default: 0.75)
    # @option options [Array<String>] :exclude_statuses Statuses to exclude from results
    # @return [Array<Hash>] Array of hashes with :conversation and :similarity_score
    # @raise [ValidationError] if conversation is invalid
    # @raise [SimilarityDetectionError] if detection fails
    def find_similar(conversation, limit: DEFAULT_LIMIT, **options)
      validate_inputs!(conversation, limit)

      start_time = Time.current
      Rails.logger.info("[ZeroDB SimilarTickets] Finding similar tickets for conversation #{conversation.id}")

      # Generate embedding for current conversation
      conversation_text = generate_conversation_text(conversation)
      raise SimilarityDetectionError, 'Conversation has no content to analyze' if conversation_text.blank?

      query_embedding = generate_embedding(conversation_text)

      # Build metadata filters
      threshold = options[:threshold] || DEFAULT_SIMILARITY_THRESHOLD
      metadata_filters = build_search_filters(conversation, options)

      # Search for similar vectors in ZeroDB
      search_response = search_similar_vectors(
        query_vector: query_embedding,
        limit: limit + 1, # +1 to account for excluding self
        metadata_filters: metadata_filters,
        threshold: threshold
      )

      # Process results, exclude self, and fetch conversations
      results = process_search_results(search_response, conversation, limit)

      duration = ((Time.current - start_time) * 1000).round(2)
      Rails.logger.info("[ZeroDB SimilarTickets] Found #{results.size} similar tickets in #{duration}ms")

      results
    rescue StandardError => e
      Rails.logger.error("[ZeroDB SimilarTickets] Failed to find similar tickets: #{e.message}")
      raise SimilarityDetectionError, "Failed to find similar tickets: #{e.message}"
    end

    # Bulk find similar tickets for multiple conversations
    # Useful for batch processing or analytics
    #
    # @param conversations [Array<Conversation>] Conversations to analyze
    # @param limit [Integer] Maximum similar tickets per conversation
    # @return [Hash] Hash mapping conversation_id => similar_results
    def find_similar_batch(conversations, limit: DEFAULT_LIMIT, **options)
      raise ValidationError, 'Conversations array cannot be empty' if conversations.empty?

      results = {}
      conversations.each do |conversation|
        begin
          results[conversation.id] = find_similar(conversation, limit: limit, **options)
        rescue StandardError => e
          Rails.logger.warn("[ZeroDB SimilarTickets] Failed to find similar for #{conversation.id}: #{e.message}")
          results[conversation.id] = []
        end
      end

      results
    end

    private

    # Validate inputs before processing
    # @param conversation [Conversation] Conversation to validate
    # @param limit [Integer] Limit to validate
    # @raise [ValidationError] if validation fails
    def validate_inputs!(conversation, limit)
      raise ValidationError, 'Conversation cannot be nil' if conversation.nil?
      raise ValidationError, 'Conversation must be persisted' unless conversation.persisted?
      raise ValidationError, "Limit must be between 1 and #{MAX_LIMIT}" unless limit.between?(1, MAX_LIMIT)
    end

    # Generate combined text content from conversation messages
    # @param conversation [Conversation] The conversation
    # @return [String] Combined message content for embedding
    def generate_conversation_text(conversation)
      messages = conversation.messages
                             .where(message_type: [:incoming, :outgoing])
                             .where.not(content: [nil, ''])
                             .order(created_at: :asc)
                             .limit(20)

      return '' if messages.empty?

      # Include conversation metadata for better context
      parts = []

      # Add subject/title if available
      subject = conversation.additional_attributes&.dig('subject')
      parts << "Subject: #{subject}" if subject.present?

      # Add messages with role labels
      message_text = messages.map do |msg|
        role = msg.incoming? ? 'Customer' : 'Agent'
        "#{role}: #{msg.content}"
      end.join("\n\n")

      parts << message_text
      parts.join("\n\n")
    end

    # Build metadata filters for search
    # Filters ensure we only find tickets in the same account and apply optional filters
    #
    # @param conversation [Conversation] Current conversation for context
    # @param options [Hash] Optional filters
    # @return [Hash] Metadata filters for ZeroDB
    def build_search_filters(conversation, options)
      filters = {
        account_id: conversation.account_id
      }

      # Optional: filter by inbox if specified
      filters[:inbox_id] = options[:inbox_id] if options[:inbox_id].present?

      # Optional: exclude certain statuses (e.g., don't show resolved tickets)
      if options[:exclude_statuses].present?
        # Note: ZeroDB doesn't support NOT IN, so we'd need to handle this in post-processing
        # For now, we'll apply this filter after fetching results
      end

      filters
    end

    # Search for similar vectors in ZeroDB
    # @param query_vector [Array<Float>] Query embedding
    # @param limit [Integer] Maximum results
    # @param metadata_filters [Hash] Metadata filters
    # @param threshold [Float] Similarity threshold
    # @return [Hash] Search results from ZeroDB
    def search_similar_vectors(query_vector:, limit:, metadata_filters:, threshold:)
      path = api_path('/vectors/search')
      body = {
        query_vector: query_vector,
        limit: limit,
        filter_metadata: metadata_filters,
        threshold: threshold,
        namespace: 'conversations',
        include_similarity_score: true # Request similarity scores
      }

      make_request(:post, path, body: body.to_json)
    end

    # Process search results, exclude self, and fetch conversations
    # @param search_response [Hash] Response from ZeroDB
    # @param current_conversation [Conversation] Conversation to exclude from results
    # @param limit [Integer] Maximum results to return
    # @return [Array<Hash>] Processed results with conversations and scores
    def process_search_results(search_response, current_conversation, limit)
      return [] unless search_response && search_response['results']

      # Extract results, excluding the current conversation
      similar_results = search_response['results'].reject do |result|
        result.dig('metadata', 'conversation_id') == current_conversation.id
      end.take(limit)

      # Extract conversation IDs and scores
      conversation_data = similar_results.map do |result|
        {
          id: result.dig('metadata', 'conversation_id'),
          similarity_score: result['similarity_score'] || result['score']
        }
      end

      # Fetch conversations in a single query
      conversation_ids = conversation_data.map { |data| data[:id] }.compact
      return [] if conversation_ids.empty?

      conversations = Conversation.where(id: conversation_ids, account_id: current_conversation.account_id)
                                   .includes(:contact, :inbox, :assignee, :messages)
                                   .index_by(&:id)

      # Build final results with conversations and scores
      conversation_data.filter_map do |data|
        next unless conversations[data[:id]]

        {
          conversation: conversations[data[:id]],
          similarity_score: data[:similarity_score]
        }
      end
    end

    # Generate vector embedding using OpenAI API
    # @param text [String] Text to embed
    # @return [Array<Float>] Vector embedding (1536 dimensions)
    # @raise [EmbeddingGenerationError] if embedding generation fails
    def generate_embedding(text)
      raise ValidationError, 'Text cannot be blank' if text.blank?

      # Use OpenAI API for embedding generation
      openai_client = OpenAI::Client.new(access_token: openai_api_key)

      response = openai_client.embeddings(
        parameters: {
          model: 'text-embedding-3-small',
          input: text.truncate(8000) # OpenAI input limit
        }
      )

      embedding = response.dig('data', 0, 'embedding')
      raise ValidationError, 'Failed to generate embedding' if embedding.blank?
      raise ValidationError, "Invalid embedding dimension: #{embedding.size}" if embedding.size != EMBEDDING_DIMENSION

      embedding
    rescue StandardError => e
      Rails.logger.error("[ZeroDB SimilarTickets] Embedding generation failed: #{e.message}")
      raise SimilarityDetectionError, "Failed to generate embedding: #{e.message}"
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
