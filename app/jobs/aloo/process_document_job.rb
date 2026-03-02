# frozen_string_literal: true

require 'shellwords'

module Aloo
  class ProcessDocumentJob < ApplicationJob
    queue_as :low
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    # Chunk size for splitting documents
    CHUNK_SIZE = 1000
    CHUNK_OVERLAP = 200

    # Supported file types
    SUPPORTED_TYPES = {
      'application/pdf' => :process_pdf,
      'text/plain' => :process_text,
      'text/markdown' => :process_text,
      'text/csv' => :process_csv,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => :process_xlsx,
      'application/vnd.ms-excel' => :process_xls,
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => :process_docx,
      'application/msword' => :process_doc,
      'application/vnd.openxmlformats-officedocument.presentationml.presentation' => :process_pptx
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

        # Tabular processors (CSV/XLSX) return pre-chunked arrays with headers per chunk;
        # prose processors return a single string for generic chunking.
        if content.is_a?(Array)
          chunks = content
        else
          return mark_failed('No content extracted') if content.blank?

          chunks = chunk_content(content)
        end
        return mark_failed('No chunks created') if chunks.empty?

        # Create embeddings for each chunk
        create_embeddings(chunks)

        # Mark as available (successfully processed)
        @document.update!(
          status: :available,
          metadata: @document.metadata.merge('processed_at' => Time.current.iso8601)
        )

        Rails.logger.info("[Aloo::ProcessDocumentJob] Processed document #{document_id}: #{chunks.size} chunks")
      rescue StandardError => e
        mark_failed(e.message)
        raise
      end
    end

    private

    def extract_content
      case @document.source_type
      when 'file'
        extract_file_content
      when 'website'
        extract_website_content
      when 'text', 'article'
        extract_text_content
      end
    end

    def extract_text_content
      @document.text_content
    end

    def extract_file_content
      return nil unless @document.file.attached?

      content_type = @document.file.content_type
      processor = SUPPORTED_TYPES[content_type]

      unless processor
        Rails.logger.warn("[Aloo::ProcessDocumentJob] Unsupported file type: #{content_type}")
        return nil
      end

      send(processor)
    end

    def extract_website_content
      return nil if @document.source_url.blank?

      # Determine scraping mode: selected pages, crawl full site, or single page
      selected_pages = @document.selected_pages
      crawl_full_site = selected_pages.blank? && ActiveModel::Type::Boolean.new.cast(@document.metadata['crawl_full_site'])

      scraper = Aloo::WebScrapingService.new(
        url: @document.source_url,
        crawl_full_site: crawl_full_site,
        selected_pages: selected_pages.presence
      )

      result = scraper.perform

      @document.update!(
        metadata: @document.metadata.merge(
          'pages_scraped' => result[:pages].size,
          'scrape_errors' => result[:errors]
        )
      )

      return nil if result[:pages].empty?

      result[:pages].map do |page|
        "## #{page[:title]}\nURL: #{page[:url]}\n\n#{page[:content]}"
      end.join("\n\n---\n\n")
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
      content = @document.file.download
      ensure_utf8(content)
    rescue StandardError => e
      Rails.logger.error("[Aloo::ProcessDocumentJob] Text processing failed: #{e.message}")
      nil
    end

    def process_csv
      require 'csv'

      content = ensure_utf8(@document.file.download)
      csv = CSV.parse(content, headers: true)
      return nil if csv.empty?

      # Return pre-chunked array: small batches of 3 rows in key-value format.
      # Each row is fully self-descriptive (e.g. "Store_Name: Sephora, Category: Beauty")
      # so every chunk has high semantic signal for embedding search.
      csv.each_slice(3).filter_map do |batch|
        rows = batch.map { |row| row.to_h.compact.map { |k, v| "#{k}: #{v}" }.join(', ') }
        chunk = rows.join("\n")
        (chunk.presence)
      end
    rescue StandardError => e
      Rails.logger.error("[Aloo::ProcessDocumentJob] CSV processing failed: #{e.message}")
      nil
    end

    def process_xlsx
      require 'roo'

      tempfile = download_to_tempfile
      spreadsheet = Roo::Excelx.new(tempfile.path)
      extract_spreadsheet_text(spreadsheet)
    rescue StandardError => e
      Rails.logger.error("[Aloo::ProcessDocumentJob] XLSX processing failed: #{e.message}")
      nil
    ensure
      tempfile&.close
      tempfile&.unlink
    end

    def process_xls
      require 'roo'
      require 'roo-xls'

      tempfile = download_to_tempfile
      spreadsheet = Roo::Excel.new(tempfile.path)
      extract_spreadsheet_text(spreadsheet)
    rescue StandardError => e
      Rails.logger.error("[Aloo::ProcessDocumentJob] XLS processing failed: #{e.message}")
      nil
    ensure
      tempfile&.close
      tempfile&.unlink
    end

    # Returns pre-chunked Array: small batches of 3 data rows in key-value format.
    # First row is treated as column headers; each data row becomes self-descriptive
    # (e.g. "Store_Name: Sephora, Category: Beauty") for better embedding search.
    def extract_spreadsheet_text(spreadsheet)
      chunks = []

      spreadsheet.sheets.each do |sheet_name|
        spreadsheet.default_sheet = sheet_name
        first_row = spreadsheet.first_row
        last_row = spreadsheet.last_row
        next unless first_row && last_row

        cols = spreadsheet.first_column..spreadsheet.last_column
        headers = cols.map { |col| spreadsheet.cell(first_row, col).to_s }

        data_range = (first_row + 1)..last_row
        unless data_range.any?
          chunks << "Sheet: #{sheet_name}\n#{headers.join(' | ')}"
          next
        end

        data_range.each_slice(3) do |row_indices|
          rows = row_indices.map do |row_idx|
            values = cols.map { |col_idx| spreadsheet.cell(row_idx, col_idx).to_s }
            headers.zip(values).map { |h, v| "#{h}: #{v}" }.join(', ')
          end
          chunks << "Sheet: #{sheet_name}\n#{rows.join("\n")}"
        end
      end

      chunks.presence
    end

    def process_docx
      require 'docx'

      tempfile = download_to_tempfile
      doc = Docx::Document.open(tempfile.path)
      paragraphs = doc.paragraphs.map(&:text).reject(&:blank?)
      paragraphs.join("\n\n")
    rescue StandardError => e
      Rails.logger.error("[Aloo::ProcessDocumentJob] DOCX processing failed: #{e.message}")
      nil
    ensure
      tempfile&.close
      tempfile&.unlink
    end

    def process_doc
      tempfile = download_to_tempfile

      if system('which antiword > /dev/null 2>&1')
        output = `antiword #{Shellwords.escape(tempfile.path)} 2>&1`
        return output if $CHILD_STATUS.success? && output.present?
      end

      Rails.logger.warn('[Aloo::ProcessDocumentJob] .doc format requires antiword to be installed')
      nil
    rescue StandardError => e
      Rails.logger.error("[Aloo::ProcessDocumentJob] DOC processing failed: #{e.message}")
      nil
    ensure
      tempfile&.close
      tempfile&.unlink
    end

    def process_pptx
      require 'zip'
      require 'nokogiri'

      tempfile = download_to_tempfile
      slides = extract_pptx_slides(tempfile.path)
      slides.join("\n\n---\n\n")
    rescue StandardError => e
      Rails.logger.error("[Aloo::ProcessDocumentJob] PPTX processing failed: #{e.message}")
      nil
    ensure
      tempfile&.close
      tempfile&.unlink
    end

    def extract_pptx_slides(path)
      slides = []
      Zip::File.open(path) do |zip|
        entries = zip.glob('ppt/slides/slide*.xml').sort_by { |e| e.name[/slide(\d+)\.xml/, 1].to_i }
        entries.each_with_index do |entry, idx|
          texts = extract_pptx_slide_text(entry)
          slides << "## Slide #{idx + 1}\n#{texts.join(' ')}" if texts.any?
        end
      end
      slides
    end

    def extract_pptx_slide_text(entry)
      xml = Nokogiri::XML(entry.get_input_stream.read)
      xml.xpath('//a:t', 'a' => 'http://schemas.openxmlformats.org/drawingml/2006/main').map(&:text)
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
      Aloo::Embedding.create_from_chunks(chunks: chunks, document: @document)
    end

    def mark_failed(error_message)
      @document.update!(
        status: 'failed',
        metadata: @document.metadata.merge('error' => error_message)
      )
      Rails.logger.error("[Aloo::ProcessDocumentJob] Document #{@document.id} failed: #{error_message}")
    end

    def ensure_utf8(content)
      return content if content.encoding == Encoding::UTF_8 && content.valid_encoding?

      # Try detecting from common encodings (Windows-1252 is typical for Excel-exported CSVs)
      [Encoding::UTF_8, Encoding::Windows_1252, Encoding::ISO_8859_1].each do |enc|
        trial = content.dup.force_encoding(enc)
        return trial.encode(Encoding::UTF_8) if trial.valid_encoding?
      end

      # Fallback: force UTF-8 and replace invalid bytes
      content.dup.force_encoding(Encoding::UTF_8).encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "\uFFFD")
    end
  end
end
