# frozen_string_literal: true

module Aloo
  class Embedding < ApplicationRecord
    self.table_name = 'aloo_embeddings'

    include Aloo::AccountScoped

    has_neighbors :embedding

    EMBEDDING_MODEL = 'text-embedding-3-small'
    BATCH_SIZE = 100
    MAX_TEXT_LENGTH = 8000
    MIN_CONTENT_LENGTH = 20

    belongs_to :assistant, class_name: 'Aloo::Assistant', foreign_key: 'aloo_assistant_id', inverse_of: :embeddings
    belongs_to :document, class_name: 'Aloo::Document', foreign_key: 'aloo_document_id', optional: true, inverse_of: :embeddings

    validates :content, presence: true

    scope :with_embedding, -> { where.not(embedding: nil) }
    scope :for_search, -> { with_embedding }

    # Generate embedding vector for any text (queries, memories, etc.)
    # @param text [String] Text to embed
    # @param account [Account] Account for tenant tracking
    # @return [Array<Float>] The embedding vector
    def self.embed_text(text, account:)
      return nil if text.blank?

      truncated = truncate_text(text)
      result = Embedders::DocumentEmbedder.call(text: truncated, tenant: account)
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

      # Sanitize and filter out empty/too-short chunks, preserving original indices
      sanitized_chunks = chunks.each_with_index.filter_map do |text, index|
        sanitized = sanitize_content(text)
        [sanitized, index] if sanitized.length >= MIN_CONTENT_LENGTH
      end

      return [] if sanitized_chunks.empty?

      sanitized_chunks.each_slice(BATCH_SIZE) do |batch_with_indices|
        texts = batch_with_indices.map(&:first)
        result = Embedders::DocumentEmbedder.call(texts: texts, tenant: account)

        batch_with_indices.each_with_index do |(text, original_index), batch_index|
          truncated = truncate_text(text)

          embedding = create!(
            account: account,
            assistant: assistant,
            document: document,
            content: truncated,
            embedding: result.vectors[batch_index],
            metadata: {
              chunk_index: original_index,
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

    # Get similarity score (only valid after nearest_neighbors query)
    def similarity
      return nil unless respond_to?(:neighbor_distance) && neighbor_distance

      1.0 - neighbor_distance
    end

    # Format embedding for LLM context
    # @return [String] Formatted string with source and content
    def to_llm
      title = document&.title || 'Unknown Source'
      "Source: #{title}\n#{content}"
    end

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

    # Sanitize content for embedding and storage
    # Removes noise that doesn't contribute to semantic meaning
    # @param text [String] Raw text content
    # @return [String] Cleaned text
    def self.sanitize_content(text)
      return '' if text.blank?

      sanitized = text
                  .gsub(/!\[.*?\]\(.*?\)/, '')                                       # Remove markdown images
                  .gsub(%r{https?://[^\s)]+\.(?:png|jpg|jpeg|gif|svg|webp)[^\s]*}i, '') # Remove full image URLs
                  .gsub(/[^\s()\[\]]+\.(?:png|jpg|jpeg|gif|svg|webp)(?:\?[^\s)]*)?/i, '') # Remove partial image URLs
                  .gsub(/\[[\s\n]*\]\([^)]*\)/, '')                                  # Remove empty markdown links
                  .gsub(/\[([^\]]*)\]\(\.[^)]*\)/m, '\1')                            # Convert relative links to plain text
                  .gsub(/\]\(\.[^)]*\)/, '')                                         # Remove broken link endings
                  .gsub(/^\[?\s*\)/, '')                                             # Remove orphan ) at line start
                  .gsub(/\[\s*$/, '')                                                # Remove orphan [ at line end
                  .gsub(/[\u{1F300}-\u{1F9FF}]/, '')                                 # Remove emojis
                  .gsub(/^[ \t]+|[ \t]+$/, '')                                       # Remove leading/trailing whitespace on each line
                  .gsub(/[ \t]{2,}/, ' ')                                            # Collapse multiple spaces/tabs to single
                  .gsub(/\n{3,}/, "\n\n")                                            # Collapse 3+ newlines to 2

      # Remove duplicate consecutive lines and collapse resulting empty lines
      deduplicate_lines(sanitized)
        .gsub(/\n{3,}/, "\n\n")
        .strip
    end
    private_class_method :sanitize_content

    # Remove duplicate consecutive non-empty lines while preserving structure
    def self.deduplicate_lines(text)
      lines = text.split("\n")
      result = []
      last_content_line = nil

      lines.each do |line|
        if line.strip.empty?
          result << line
        elsif line != last_content_line
          result << line
          last_content_line = line
        end
      end

      result.join("\n")
    end
    private_class_method :deduplicate_lines
  end
end
