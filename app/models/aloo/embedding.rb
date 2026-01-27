# frozen_string_literal: true

module Aloo
  class Embedding < ApplicationRecord
    self.table_name = 'aloo_embeddings'

    include Aloo::AccountScoped
    include Aloo::Embeddable

    EMBEDDING_MODEL = 'text-embedding-3-small'
    BATCH_SIZE = 100
    MAX_TEXT_LENGTH = 8000

    belongs_to :assistant, class_name: 'Aloo::Assistant', foreign_key: 'aloo_assistant_id', inverse_of: :embeddings
    belongs_to :document, class_name: 'Aloo::Document', foreign_key: 'aloo_document_id', optional: true, inverse_of: :embeddings

    validates :content, presence: true

    scope :for_search, -> { with_embedding }

    # ─────────────────────────────────────────────────────────────────
    # Class methods for embedding generation
    # ─────────────────────────────────────────────────────────────────

    # Generate embedding vector for any text (queries, memories, etc.)
    # @param text [String] Text to embed
    # @param account [Account] Account for tenant tracking
    # @return [Array<Float>] The embedding vector
    def self.embed_text(text, account:)
      return nil if text.blank?

      result = Embedders::DocumentEmbedder.call(text: text, tenant: account)
      result.vector
    rescue RubyLLM::Error => e
      Rails.logger.error("[Aloo::Embedding] Embedding failed: #{e.message}")
      raise
    end

    # Create embeddings for document chunks (batch operation)
    # @param chunks [Array<String>] Text chunks to embed
    # @param document [Aloo::Document] The source document
    # @return [Array<Aloo::Embedding>] Created embedding records
    def self.create_from_chunks(chunks:, document:)
      return [] if chunks.blank?

      account = document.account
      assistant = document.assistant
      embeddings = []

      chunks.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
        result = Embedders::DocumentEmbedder.call(texts: batch, tenant: account)

        batch.each_with_index do |text, index|
          chunk_index = (batch_index * BATCH_SIZE) + index
          truncated = truncate_text(text)

          embedding = create!(
            account: account,
            assistant: assistant,
            document: document,
            content: truncated,
            embedding: result.vectors[index],
            metadata: {
              chunk_index: chunk_index,
              token_count: estimate_tokens(truncated),
              model: EMBEDDING_MODEL
            }
          )
          embeddings << embedding
        end
      end

      embeddings
    rescue RubyLLM::Error => e
      Rails.logger.error("[Aloo::Embedding] Batch embedding failed: #{e.message}")
      raise
    end

    # Delete all embeddings for a document
    # @param document [Aloo::Document] The document
    # @return [Integer] Number of deleted records
    def self.delete_for_document(document)
      where(document: document, account: document.account).destroy_all.count
    end

    # Search knowledge base for relevant embeddings
    # @param query [String] The search query
    # @param assistant [Aloo::Assistant] The assistant to search within
    # @param limit [Integer] Maximum results to return
    # @param min_similarity [Float] Minimum similarity threshold (0.0-1.0)
    # @param source_types [Array<String>] Optional filter by document source types
    # @return [Array<Aloo::Embedding>] Matching embeddings sorted by similarity
    def self.search(query, assistant:, limit: 10, min_similarity: 0.3, source_types: nil)
      return [] if query.blank?

      vector = embed_text(query, account: assistant.account)
      return [] unless vector

      scope = joins(:document)
              .where(assistant: assistant)
              .where(account: assistant.account)
              .where(aloo_documents: { status: :available })

      scope = scope.where(aloo_documents: { source_type: source_types }) if source_types.present?

      results = scope
                .nearest_neighbors(:embedding, vector, distance: 'cosine')
                .limit(limit * 2)  # Fetch extra to filter by similarity
                .includes(:document)

      # Filter by similarity threshold and return limited results
      results.select { |e| (1.0 - e.neighbor_distance) >= min_similarity }.first(limit)
    rescue RubyLLM::Error => e
      Rails.logger.error("[Aloo::Embedding] Search failed: #{e.message}")
      []
    end

    # Re-embed a document (delete old, create new)
    # @param document [Aloo::Document] The document
    # @param chunks [Array<String>] New text chunks
    # @return [Array<Aloo::Embedding>] New embedding records
    def self.reembed_document(document:, chunks:)
      delete_for_document(document)
      create_from_chunks(chunks: chunks, document: document)
    end

    # ─────────────────────────────────────────────────────────────────
    # Instance methods
    # ─────────────────────────────────────────────────────────────────

    # For Embeddable concern - content to embed
    def embedding_content
      content
    end

    # Build display format for context
    def to_context_format
      embedding_content
    end

    # Get source info
    def source_info
      {
        document_title: document&.title,
        document_url: document&.source_url,
        chunk_index: metadata['chunk_index']
      }
    end

    # Get similarity score (only valid after nearest_neighbors query)
    def similarity
      return nil unless respond_to?(:neighbor_distance) && neighbor_distance

      1.0 - neighbor_distance
    end

    # ─────────────────────────────────────────────────────────────────
    # Private class methods
    # ─────────────────────────────────────────────────────────────────

    def self.truncate_text(text)
      return '' if text.blank?

      text.to_s.truncate(MAX_TEXT_LENGTH, omission: '')
    end
    private_class_method :truncate_text

    def self.estimate_tokens(text)
      return 0 if text.blank?

      (text.length / 4.0).ceil
    end
    private_class_method :estimate_tokens
  end
end
