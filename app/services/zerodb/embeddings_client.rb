module Zerodb
  # Client for ZeroDB Embeddings API
  # Provides methods to generate embeddings and store documents with embeddings
  class EmbeddingsClient < BaseService
    EMBEDDINGS_ENDPOINT = '/embeddings'
    GENERATE_ENDPOINT = "#{EMBEDDINGS_ENDPOINT}/generate"
    EMBED_AND_STORE_ENDPOINT = "#{EMBEDDINGS_ENDPOINT}/embed-and-store"

    # Generate embedding for a single text input
    # @param text [String] Text to generate embedding for
    # @param options [Hash] Optional parameters
    # @option options [String] :model Model name to use for embeddings (default: 'text-embedding-3-small')
    # @return [Hash] Response containing embedding vector and metadata
    # @raise [ValidationError] if text is empty or invalid
    # @raise [ZeroDBError] if API request fails
    def generate_embedding(text, options = {})
      raise ValidationError, 'Text cannot be blank' if text.blank?

      payload = {
        texts: [text],  # API expects array of texts
        model: options[:model] || 'BAAI/bge-small-en-v1.5'  # ZeroDB uses BGE models, not OpenAI
      }

      response = make_request(:post, api_path(GENERATE_ENDPOINT), body: payload.to_json)
      # Return first embedding from the array (BGE models return 384 dimensions)
      response['embeddings']&.first || response
    end

    # Generate embeddings and store multiple documents in vector database
    # @param documents [Array<Hash>] Array of documents to embed and store
    # @option documents [String] :text Text content to embed
    # @option documents [Hash] :metadata Optional metadata for the document
    # @option documents [String] :id Optional document ID
    # @param options [Hash] Optional parameters
    # @option options [String] :namespace Namespace to store vectors in (default: 'default')
    # @option options [String] :model Model name to use for embeddings
    # @return [Hash] Response containing stored document IDs and vectors
    # @raise [ValidationError] if documents array is empty or invalid
    # @raise [ZeroDBError] if API request fails
    def embed_and_store(documents, options = {})
      raise ValidationError, 'Documents array cannot be empty' if documents.blank?
      raise ValidationError, 'Documents must be an array' unless documents.is_a?(Array)

      validate_documents!(documents)

      payload = {
        documents: documents,
        namespace: options[:namespace] || 'default',
        model: options[:model] || 'BAAI/bge-small-en-v1.5'
      }

      make_request(:post, api_path(EMBED_AND_STORE_ENDPOINT), body: payload.to_json)
    end

    # Batch generate embeddings for multiple texts
    # @param texts [Array<String>] Array of texts to generate embeddings for
    # @param options [Hash] Optional parameters
    # @option options [String] :model Model name to use for embeddings
    # @return [Hash] Response containing array of embeddings
    # @raise [ValidationError] if texts array is empty or invalid
    # @raise [ZeroDBError] if API request fails
    def batch_generate_embeddings(texts, options = {})
      raise ValidationError, 'Texts array cannot be empty' if texts.blank?
      raise ValidationError, 'Texts must be an array' unless texts.is_a?(Array)

      texts.each_with_index do |text, index|
        raise ValidationError, "Text at index #{index} cannot be blank" if text.blank?
      end

      payload = {
        texts: texts,
        model: options[:model] || 'BAAI/bge-small-en-v1.5'
      }

      make_request(:post, api_path("#{EMBEDDINGS_ENDPOINT}/batch"), body: payload.to_json)
    end

    private

    # Validate documents structure before sending to API
    # @param documents [Array<Hash>] Documents to validate
    # @raise [ValidationError] if any document is invalid
    def validate_documents!(documents)
      documents.each_with_index do |doc, index|
        raise ValidationError, "Document at index #{index} must be a hash" unless doc.is_a?(Hash)
        raise ValidationError, "Document at index #{index} must have 'text' field" if doc[:text].blank? && doc['text'].blank?

        text_content = doc[:text] || doc['text']
        raise ValidationError, "Text in document at index #{index} cannot be blank" if text_content.blank?
      end
    end
  end
end
