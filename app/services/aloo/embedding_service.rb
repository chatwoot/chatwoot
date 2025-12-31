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
    # @param embeddable [ActiveRecord::Base] The record to associate embedding with
    # @param chunk_index [Integer] Optional index for multi-chunk documents
    # @return [Aloo::Embedding] The created embedding record
    def embed_and_store(text:, embeddable:, chunk_index: 0)
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
          embeddable: embeddable,
          content: truncated_text,
          embedding: vector,
          chunk_index: chunk_index,
          token_count: estimate_tokens(truncated_text),
          model: EMBEDDING_MODEL
        )
      end
    end

    # Batch embed multiple texts for a single embeddable
    # @param texts [Array<String>] Array of text chunks to embed
    # @param embeddable [ActiveRecord::Base] The record to associate embeddings with
    # @return [Array<Aloo::Embedding>] Array of created embedding records
    def batch_embed_and_store(texts:, embeddable:)
      return [] if texts.blank?

      embeddings = []
      texts.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
        batch_embeddings = generate_batch_embeddings(batch)

        batch.each_with_index do |text, index|
          chunk_index = (batch_index * BATCH_SIZE) + index
          vector = batch_embeddings[index]

          embedding = Aloo::Embedding.create!(
            account: @account,
            embeddable: embeddable,
            content: truncate_text(text),
            embedding: vector,
            chunk_index: chunk_index,
            token_count: estimate_tokens(text),
            model: EMBEDDING_MODEL
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
      result.vectors.first
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

      result = RubyLLM.embed(truncated_texts, model: EMBEDDING_MODEL)
      result.vectors
    rescue RubyLLM::Error => e
      Rails.logger.error("[Aloo::EmbeddingService] Batch embedding failed: #{e.message}")
      raise
    end

    # Delete all embeddings for an embeddable
    # @param embeddable [ActiveRecord::Base] The record whose embeddings to delete
    # @return [Integer] Number of deleted embeddings
    def delete_embeddings_for(embeddable)
      Aloo::Embedding.where(
        embeddable_type: embeddable.class.name,
        embeddable_id: embeddable.id,
        account: @account
      ).destroy_all.count
    end

    # Re-embed an embeddable (delete old and create new)
    # @param embeddable [ActiveRecord::Base] The record to re-embed
    # @param texts [Array<String>] New text chunks to embed
    # @return [Array<Aloo::Embedding>] Array of new embedding records
    def reembed(embeddable:, texts:)
      delete_embeddings_for(embeddable)
      batch_embed_and_store(texts: texts, embeddable: embeddable)
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
