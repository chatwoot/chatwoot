# frozen_string_literal: true

# Orchestrates the full document ingestion pipeline:
#   1. Extract text (from plain text, file upload, or URL crawl)
#   2. Chunk the text
#   3. Generate embeddings and store as KnowledgeDocument records
module Rag
  class DocumentIngestionJob < ApplicationJob
    queue_as :low

    retry_on Llm::Client::RateLimitError, wait: :polynomially_longer, attempts: 5
    retry_on Llm::Client::TimeoutError, wait: 30.seconds, attempts: 3
    discard_on ActiveRecord::RecordNotFound

    def perform(knowledge_base_id:, text: nil, title: 'Document', source_type: 'text',
                source_url: nil, content_type: nil, file_size: nil)
      knowledge_base = Saas::KnowledgeBase.find(knowledge_base_id)
      account = knowledge_base.account

      knowledge_base.update!(status: :processing)

      # Step 1: Get the raw text
      raw_text = resolve_text(text: text, source_type: source_type, source_url: source_url)

      if raw_text.blank?
        knowledge_base.update!(status: :error)
        return
      end

      # Step 2: Chunk the text
      chunker = Rag::TextChunker.new
      chunks = chunker.split(raw_text)

      # Step 3: Embed and store
      embedding_service = Rag::EmbeddingService.new(account: account)
      embedding_service.embed_chunks(
        knowledge_base: knowledge_base,
        chunks: chunks,
        title: title,
        source_type: source_type,
        source_url: source_url,
        content_type: content_type,
        file_size: file_size
      )
    rescue StandardError => e
      knowledge_base&.update!(status: :error)
      ChatwootExceptionTracker.new(e, account: account).capture_exception
    end

    private

    def resolve_text(text:, source_type:, source_url:)
      case source_type.to_s
      when 'text', 'file_upload'
        text
      when 'url'
        crawl_url(source_url)
      else
        text
      end
    end

    def crawl_url(url)
      return nil if url.blank?

      Rag::UrlCrawler.new.crawl(url)
    end
  end
end
