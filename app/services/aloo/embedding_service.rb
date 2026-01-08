# frozen_string_literal: true

module Aloo
  class EmbeddingService
    EMBEDDING_MODEL = 'text-embedding-3-small'
    BATCH_SIZE = 100
    MAX_TEXT_LENGTH = 8000 # Approximate token limit for embedding model

    def initialize(account:)
      @account = account
      validate_account!
    end

    # Generate and store embedding for a single text
    # @param text [String] The text to embed
    # @param document [Aloo::Document] The document to associate embedding with
    # @param chunk_index [Integer] Optional index for multi-chunk documents
    # @return [Aloo::Embedding] The created embedding record
    def embed_and_store(text:, document:, chunk_index: 0)
      return nil if text.blank?

      truncated_text = truncate_text(text)
      vector = generate_embedding(truncated_text)

      Aloo::Trace.record_with_timing(
        trace_type: 'embedding',
        account: @account,
        input_data: { text_length: truncated_text.length, chunk_index: chunk_index }
      ) do
        Aloo::Embedding.create!(
          account: @account,
          assistant: document.assistant,
          document: document,
          content: truncated_text,
          embedding: vector,
          metadata: {
            chunk_index: chunk_index,
            token_count: estimate_tokens(truncated_text),
            model: EMBEDDING_MODEL
          }
        )
      end
    end

    # Batch embed multiple texts for a single document
    # @param texts [Array<String>] Array of text chunks to embed
    # @param document [Aloo::Document] The document to associate embeddings with
    # @return [Array<Aloo::Embedding>] Array of created embedding records
    def batch_embed_and_store(texts:, document:)
      return [] if texts.blank?

      embeddings = []
      texts.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
        batch_embeddings = generate_batch_embeddings(batch)

        batch.each_with_index do |text, index|
          chunk_index = (batch_index * BATCH_SIZE) + index
          vector = batch_embeddings[index]

          embedding = Aloo::Embedding.create!(
            account: @account,
            assistant: document.assistant,
            document: document,
            content: truncate_text(text),
            embedding: vector,
            metadata: {
              chunk_index: chunk_index,
              token_count: estimate_tokens(text),
              model: EMBEDDING_MODEL
            }
          )
          embeddings << embedding
        end
      end

      embeddings
    end

    # Generate embedding vector without storing
    # @param text [String] The text to embed
    # @return [Array<Float>] The embedding vector
    def generate_embedding(text)
      return nil if text.blank?

      truncated_text = truncate_text(text)

      result = RubyLLM.embed(truncated_text, model: EMBEDDING_MODEL)
      # RubyLLM.embed returns an Embedding object where .vectors is the vector array directly
      result.vectors
    rescue RubyLLM::Error => e
      Rails.logger.error("[Aloo::EmbeddingService] Embedding failed: #{e.message}")
      raise
    end

    # Generate embeddings for multiple texts in batch
    # @param texts [Array<String>] Array of texts to embed
    # @return [Array<Array<Float>>] Array of embedding vectors
    def generate_batch_embeddings(texts)
      return [] if texts.blank?

      truncated_texts = texts.map { |t| truncate_text(t) }

      # For batch, we need to call embed for each text individually
      # since RubyLLM.embed with an array returns a single combined embedding
      truncated_texts.map do |text|
        result = RubyLLM.embed(text, model: EMBEDDING_MODEL)
        result.vectors
      end
    rescue RubyLLM::Error => e
      Rails.logger.error("[Aloo::EmbeddingService] Batch embedding failed: #{e.message}")
      raise
    end

    # Delete all embeddings for a document
    # @param document [Aloo::Document] The document whose embeddings to delete
    # @return [Integer] Number of deleted embeddings
    def delete_embeddings_for(document)
      Aloo::Embedding.where(
        document: document,
        account: @account
      ).destroy_all.count
    end

    # Re-embed a document (delete old and create new)
    # @param document [Aloo::Document] The document to re-embed
    # @param texts [Array<String>] New text chunks to embed
    # @return [Array<Aloo::Embedding>] Array of new embedding records
    def reembed(document:, texts:)
      delete_embeddings_for(document)
      batch_embed_and_store(texts: texts, document: document)
    end

    private

    def validate_account!
      raise ArgumentError, 'Account required' unless @account
    end

    def truncate_text(text)
      return '' if text.blank?

      text.to_s.truncate(MAX_TEXT_LENGTH, omission: '')
    end

    def estimate_tokens(text)
      return 0 if text.blank?

      # Rough estimate: ~4 characters per token
      (text.length / 4.0).ceil
    end
  end
end
