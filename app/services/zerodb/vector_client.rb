module Zerodb
  # Client for ZeroDB Vector Database API
  # Provides methods to upsert, search, and manage vector embeddings
  class VectorClient < BaseService
    VECTORS_ENDPOINT = '/vectors'
    UPSERT_ENDPOINT = "#{VECTORS_ENDPOINT}/upsert"
    SEARCH_ENDPOINT = "#{VECTORS_ENDPOINT}/search"
    DELETE_ENDPOINT = "#{VECTORS_ENDPOINT}/delete"
    BATCH_UPSERT_ENDPOINT = "#{VECTORS_ENDPOINT}/batch-upsert"

    # Default vector dimension for embeddings (OpenAI text-embedding-3-small)
    DEFAULT_DIMENSION = 1536
    SUPPORTED_DIMENSIONS = [384, 768, 1024, 1536].freeze

    # Upsert a single vector into the database
    # @param vector_id [String] Unique identifier for the vector
    # @param vector [Array<Float>] Vector embedding array
    # @param metadata [Hash] Metadata associated with the vector
    # @param options [Hash] Optional parameters
    # @option options [String] :namespace Namespace to store vector in (default: 'default')
    # @return [Hash] Response containing vector ID and status
    # @raise [ValidationError] if vector_id, vector, or metadata is invalid
    # @raise [ZeroDBError] if API request fails
    def upsert_vector(vector_id, vector, metadata = {}, options = {})
      validate_vector_params!(vector_id, vector)

      payload = {
        id: vector_id,
        vector: vector,
        metadata: metadata || {},
        namespace: options[:namespace] || 'default'
      }

      make_request(:post, api_path(UPSERT_ENDPOINT), body: payload.to_json)
    end

    # Batch upsert multiple vectors for efficiency
    # @param vectors [Array<Hash>] Array of vector objects
    # @option vectors [String] :id Vector ID
    # @option vectors [Array<Float>] :vector Vector embedding
    # @option vectors [Hash] :metadata Vector metadata
    # @param options [Hash] Optional parameters
    # @option options [String] :namespace Namespace to store vectors in
    # @return [Hash] Response containing array of inserted vector IDs
    # @raise [ValidationError] if vectors array is empty or invalid
    # @raise [ZeroDBError] if API request fails
    def batch_upsert_vectors(vectors, options = {})
      raise ValidationError, 'Vectors array cannot be empty' if vectors.blank?
      raise ValidationError, 'Vectors must be an array' unless vectors.is_a?(Array)

      validate_batch_vectors!(vectors)

      payload = {
        vectors: vectors,
        namespace: options[:namespace] || 'default'
      }

      make_request(:post, api_path(BATCH_UPSERT_ENDPOINT), body: payload.to_json)
    end

    # Search for similar vectors using semantic similarity
    # @param query_vector [Array<Float>] Query vector to search with
    # @param limit [Integer] Maximum number of results to return (default: 10)
    # @param options [Hash] Optional search parameters
    # @option options [Hash] :filters Metadata filters for search results
    # @option options [String] :namespace Namespace to search in (default: 'default')
    # @option options [Float] :threshold Similarity threshold (0.0-1.0, default: 0.7)
    # @option options [Boolean] :include_metadata Include metadata in results (default: true)
    # @option options [Boolean] :include_vectors Include vector embeddings in results (default: false)
    # @return [Hash] Response containing array of similar vectors with scores
    # @raise [ValidationError] if query_vector is invalid or limit is out of range
    # @raise [ZeroDBError] if API request fails
    def search_vectors(query_vector, limit = 10, options = {})
      validate_search_params!(query_vector, limit)

      payload = {
        query_vector: query_vector,
        limit: limit,
        namespace: options[:namespace] || 'default',
        threshold: options[:threshold] || 0.7,
        include_metadata: options.fetch(:include_metadata, true),
        include_vectors: options.fetch(:include_vectors, false)
      }

      # Add filters if provided
      payload[:filters] = options[:filters] if options[:filters].present?

      make_request(:post, api_path(SEARCH_ENDPOINT), body: payload.to_json)
    end

    # Delete a vector by ID
    # @param vector_id [String] Vector ID to delete
    # @param options [Hash] Optional parameters
    # @option options [String] :namespace Namespace containing the vector (default: 'default')
    # @return [Hash] Response containing deletion status
    # @raise [ValidationError] if vector_id is blank
    # @raise [ZeroDBError] if API request fails
    def delete_vector(vector_id, options = {})
      raise ValidationError, 'Vector ID cannot be blank' if vector_id.blank?

      payload = {
        id: vector_id,
        namespace: options[:namespace] || 'default'
      }

      make_request(:delete, api_path(DELETE_ENDPOINT), body: payload.to_json)
    end

    # Get vector by ID
    # @param vector_id [String] Vector ID to retrieve
    # @param options [Hash] Optional parameters
    # @option options [String] :namespace Namespace containing the vector (default: 'default')
    # @option options [Boolean] :include_vector Include vector embedding in response (default: true)
    # @return [Hash] Response containing vector data and metadata
    # @raise [ValidationError] if vector_id is blank
    # @raise [ZeroDBError] if API request fails
    def get_vector(vector_id, options = {})
      raise ValidationError, 'Vector ID cannot be blank' if vector_id.blank?

      query_params = {
        namespace: options[:namespace] || 'default',
        include_vector: options.fetch(:include_vector, true)
      }

      make_request(:get, api_path("#{VECTORS_ENDPOINT}/#{vector_id}"), query: query_params)
    end

    # List vectors with pagination
    # @param options [Hash] Optional parameters
    # @option options [String] :namespace Namespace to list vectors from (default: 'default')
    # @option options [Integer] :limit Number of vectors per page (default: 100)
    # @option options [Integer] :offset Pagination offset (default: 0)
    # @option options [Hash] :filters Metadata filters
    # @return [Hash] Response containing array of vectors and pagination info
    # @raise [ZeroDBError] if API request fails
    def list_vectors(options = {})
      query_params = {
        namespace: options[:namespace] || 'default',
        limit: options[:limit] || 100,
        offset: options[:offset] || 0
      }

      query_params[:filters] = options[:filters].to_json if options[:filters].present?

      make_request(:get, api_path(VECTORS_ENDPOINT), query: query_params)
    end

    private

    # Validate vector upsert parameters
    # @param vector_id [String] Vector ID
    # @param vector [Array<Float>] Vector embedding
    # @raise [ValidationError] if parameters are invalid
    def validate_vector_params!(vector_id, vector)
      raise ValidationError, 'Vector ID cannot be blank' if vector_id.blank?
      raise ValidationError, 'Vector cannot be nil' if vector.nil?
      raise ValidationError, 'Vector must be an array' unless vector.is_a?(Array)
      raise ValidationError, 'Vector cannot be empty' if vector.empty?

      validate_vector_dimension!(vector)
    end

    # Validate vector dimension
    # @param vector [Array<Float>] Vector embedding
    # @raise [ValidationError] if dimension is not supported
    def validate_vector_dimension!(vector)
      dimension = vector.length

      unless SUPPORTED_DIMENSIONS.include?(dimension)
        raise ValidationError,
              "Vector dimension #{dimension} is not supported. Supported dimensions: #{SUPPORTED_DIMENSIONS.join(', ')}"
      end
    end

    # Validate batch upsert vectors
    # @param vectors [Array<Hash>] Array of vector objects
    # @raise [ValidationError] if any vector is invalid
    def validate_batch_vectors!(vectors)
      vectors.each_with_index do |vec, index|
        raise ValidationError, "Vector at index #{index} must be a hash" unless vec.is_a?(Hash)

        vector_id = vec[:id] || vec['id']
        vector_data = vec[:vector] || vec['vector']

        raise ValidationError, "Vector at index #{index} must have 'id' field" if vector_id.blank?
        raise ValidationError, "Vector at index #{index} must have 'vector' field" if vector_data.nil?

        validate_vector_params!(vector_id, vector_data)
      end
    end

    # Validate search parameters
    # @param query_vector [Array<Float>] Query vector
    # @param limit [Integer] Result limit
    # @raise [ValidationError] if parameters are invalid
    def validate_search_params!(query_vector, limit)
      raise ValidationError, 'Query vector cannot be nil' if query_vector.nil?
      raise ValidationError, 'Query vector must be an array' unless query_vector.is_a?(Array)
      raise ValidationError, 'Query vector cannot be empty' if query_vector.empty?

      validate_vector_dimension!(query_vector)

      raise ValidationError, 'Limit must be a positive integer' unless limit.is_a?(Integer) && limit.positive?
      raise ValidationError, 'Limit cannot exceed 1000' if limit > 1000
    end
  end
end
