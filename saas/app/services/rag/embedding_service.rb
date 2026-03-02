# frozen_string_literal: true

# Generates embeddings for text chunks via LiteLLM and stores them as KnowledgeDocument records.
module Rag
  class EmbeddingService
    BATCH_SIZE = 20 # OpenAI supports up to 2048 inputs, but keep batches small for reliability

    def initialize(account:, api_key: nil)
      @account = account
      @client = Llm::Client.new(api_key: api_key)
    end

    # Embeds an array of chunk hashes [{ text:, index: }] and creates KnowledgeDocument records.
    # Returns the created documents.
    def embed_chunks(knowledge_base:, chunks:, title:, source_type: :text, source_url: nil, content_type: nil, file_size: nil)
      return [] if chunks.blank?

      documents = []

      chunks.each_slice(BATCH_SIZE) do |batch|
        texts = batch.map { |c| c[:text] }
        embeddings = fetch_embeddings(texts)

        batch.each_with_index do |chunk, idx|
          doc = Saas::KnowledgeDocument.create!(
            knowledge_base: knowledge_base,
            account: @account,
            title: "#{title} [chunk #{chunk[:index] + 1}]",
            content: chunk[:text],
            embedding: embeddings[idx],
            source_type: source_type,
            source_url: source_url,
            content_type: content_type,
            file_size: file_size,
            chunk_count: 1,
            status: :ready,
            metadata: { chunk_index: chunk[:index], total_chunks: chunks.size }
          )
          documents << doc
        end
      end

      knowledge_base.update!(status: :active)
      documents
    rescue StandardError => e
      knowledge_base.update!(status: :error)
      raise e
    end

    # Generate embedding for a single query string (for search)
    def embed_query(text)
      response = @client.embed(input: text)
      response.dig('data', 0, 'embedding')
    end

    private

    def fetch_embeddings(texts)
      response = @client.embed(input: texts)
      response['data']
        .sort_by { |d| d['index'] }
        .map { |d| d['embedding'] }
    end
  end
end
