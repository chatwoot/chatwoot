require 'pdf-reader'

class Captain::Tools::PdfExtractionService
  include ActiveModel::Validations
  include Captain::Tools::PdfValidationConcern
  include Captain::Tools::PdfContentChunkingConcern
  include Captain::Tools::PdfExtractionService::SourceHandler
  include Captain::Tools::PdfExtractionService::BlobHandler
  include Captain::Tools::PdfExtractionService::TextProcessor

  class ExtractionError < StandardError; end

  attr_reader :pdf_source, :errors

  # Fixed PDF processing limits
  MAX_PDF_SIZE = 25.megabytes
  MAX_CHUNK_SIZE = 10_000
  DOWNLOAD_TIMEOUT = 60        # Increased for larger file downloads

  def initialize(pdf_source)
    @pdf_source = pdf_source
    @errors = []
  end

  def perform
    return failure_response(['Invalid PDF source']) if pdf_source.blank?

    validation_result = validate_pdf_source
    return validation_result unless validation_result[:success]

    process_pdf_extraction
  end

  private

  def process_pdf_extraction
    content = extract_text
    return failure_response(['No text content found in PDF']) if content.blank?

    chunked_content = chunk_content(content)
    log_extraction_success(chunked_content)

    success_response(chunked_content)
  end

  def log_extraction_success(chunked_content)
    total_chars = chunked_content.sum { |chunk| chunk[:content].length }
    Rails.logger.info "PDF extraction completed: #{chunked_content.length} chunks, #{total_chars} characters"
  end
end