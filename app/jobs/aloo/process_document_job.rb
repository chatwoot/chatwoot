# frozen_string_literal: true

module Aloo
  class ProcessDocumentJob < ApplicationJob
    queue_as :low
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    # Chunk size for splitting documents
    CHUNK_SIZE = 1000
    CHUNK_OVERLAP = 100

    # Supported file types
    SUPPORTED_TYPES = {
      'application/pdf' => :process_pdf,
      'text/plain' => :process_text,
      'text/markdown' => :process_text,
      'text/csv' => :process_csv
    }.freeze

    # Process an uploaded document and create embeddings
    # @param document_id [Integer] The document ID to process
    def perform(document_id)
      @document = Aloo::Document.find_by(id: document_id)
      return unless @document

      @account = @document.account
      @assistant = @document.assistant

      begin
        @document.update!(status: 'processing')

        # Extract and process content
        content = extract_content
        return mark_failed('No content extracted') if content.blank?

        # Chunk the content
        chunks = chunk_content(content)
        return mark_failed('No chunks created') if chunks.empty?

        # Store raw content
        @document.update!(content: content)

        # Create embeddings for each chunk
        create_embeddings(chunks)

        # Mark as processed
        @document.update!(
          status: 'processed',
          processed_at: Time.current
        )

        Rails.logger.info("[Aloo::ProcessDocumentJob] Processed document #{document_id}: #{chunks.size} chunks")
      rescue StandardError => e
        mark_failed(e.message)
        raise
      end
    end

    private

    def extract_content
      return nil unless @document.file.attached?

      content_type = @document.file.content_type
      processor = SUPPORTED_TYPES[content_type]

      unless processor
        Rails.logger.warn("[Aloo::ProcessDocumentJob] Unsupported file type: #{content_type}")
        return nil
      end

      send(processor)
    end

    def process_pdf
      require 'pdf-reader'

      tempfile = download_to_tempfile
      reader = PDF::Reader.new(tempfile.path)

      pages = reader.pages.map(&:text)
      pages.join("\n\n---\n\n")
    rescue StandardError => e
      Rails.logger.error("[Aloo::ProcessDocumentJob] PDF processing failed: #{e.message}")
      nil
    ensure
      tempfile&.close
      tempfile&.unlink
    end

    def process_text
      @document.file.download
    rescue StandardError => e
      Rails.logger.error("[Aloo::ProcessDocumentJob] Text processing failed: #{e.message}")
      nil
    end

    def process_csv
      require 'csv'

      content = @document.file.download
      csv = CSV.parse(content, headers: true)

      # Convert each row to a readable format
      rows = csv.map do |row|
        row.to_h.map { |k, v| "#{k}: #{v}" }.join(', ')
      end

      rows.join("\n")
    rescue StandardError => e
      Rails.logger.error("[Aloo::ProcessDocumentJob] CSV processing failed: #{e.message}")
      nil
    end

    def download_to_tempfile
      tempfile = Tempfile.new(['document', File.extname(@document.file.filename.to_s)])
      tempfile.binmode
      tempfile.write(@document.file.download)
      tempfile.rewind
      tempfile
    end

    def chunk_content(content)
      return [] if content.blank?

      chunks = []
      position = 0

      while position < content.length
        # Get chunk with overlap consideration
        chunk_end = position + CHUNK_SIZE
        chunk = content[position...chunk_end]

        # Try to break at a natural boundary (paragraph or sentence)
        if chunk_end < content.length
          # Look for paragraph break first
          last_para = chunk.rindex("\n\n")
          if last_para && last_para > CHUNK_SIZE / 2
            chunk = content[position...(position + last_para)]
            chunk_end = position + last_para + 2 # Skip the newlines
          else
            # Look for sentence break
            last_sentence = chunk.rindex(/[.!?]\s/)
            if last_sentence && last_sentence > CHUNK_SIZE / 2
              chunk = content[position...(position + last_sentence + 1)]
              chunk_end = position + last_sentence + 2
            end
          end
        end

        chunks << chunk.strip if chunk.strip.present?

        # Move position with overlap
        position = [chunk_end - CHUNK_OVERLAP, position + 1].max
      end

      chunks
    end

    def create_embeddings(chunks)
      embedding_service = EmbeddingService.new(account: @account)
      embedding_service.batch_embed_and_store(texts: chunks, embeddable: @document)
    end

    def mark_failed(error_message)
      @document.update!(
        status: 'failed',
        metadata: @document.metadata.merge('error' => error_message)
      )
      Rails.logger.error("[Aloo::ProcessDocumentJob] Document #{@document.id} failed: #{error_message}")
    end
  end
end
