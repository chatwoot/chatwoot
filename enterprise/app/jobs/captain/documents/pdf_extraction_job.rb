class Captain::Documents::PdfExtractionJob < ApplicationJob
  queue_as :low

  def perform(document)
    return unless document.pdf_document?

    initialize_document_processing(document)
    result = extract_pdf_content(document)
    process_extraction_result(document, result)
  rescue Captain::Tools::PdfExtractionService::ExtractionError => e
    handle_pdf_extraction_error(document, e)
  end

  private

  def initialize_document_processing(document)
    document.update(status: 'in_progress')
  end

  def extract_pdf_content(document)
    pdf_source = document.file.attached? ? document.file : document.external_link
    pdf_extraction_service = Captain::Tools::PdfExtractionService.new(pdf_source)
    pdf_extraction_service.perform
  end

  def process_extraction_result(document, result)
    if result[:success] && result[:content].present?
      process_pdf_content_chunks(document, result[:content])
    else
      handle_pdf_extraction_failure(document, result)
    end
  end

  def process_pdf_content_chunks(document, content_chunks)
    Rails.logger.info "PDF extraction successful for document #{document.id}: #{content_chunks.length} chunks will be processed"

    content_chunks.each_with_index do |content_chunk, index|
      log_chunk_queueing(document, content_chunk, index, content_chunks.length)
      queue_pdf_chunk_job(document, content_chunk)
    end

    document.update(status: 'in_progress', processed_at: nil)
    Rails.logger.info "All #{content_chunks.length} chunks queued for processing for document #{document.id}"
  end

  def log_chunk_queueing(document, content_chunk, index, total_chunks)
    page_num = content_chunk[:page_number]
    content_length = content_chunk[:content].length
    Rails.logger.info "Queueing chunk #{index + 1}/#{total_chunks} for document #{document.id} " \
                      "(Page #{page_num}, #{content_length} chars)"
  end

  def queue_pdf_chunk_job(document, content_chunk)
    Captain::Tools::PdfExtractionParserJob.perform_later(
      assistant_id: document.assistant_id,
      pdf_content: content_chunk,
      document_id: document.id
    )
  end

  def handle_pdf_extraction_failure(document, result)
    error_message = result[:errors]&.join(', ') || 'Failed to extract text from PDF'
    Rails.logger.error "PDF extraction failed for document #{document.id}: #{error_message}"
    document.update(status: 'available')
  end

  def handle_pdf_extraction_error(document, error)
    Rails.logger.error "PDF extraction failed for document #{document.id}: #{error.message}"
    document.update(status: 'available')
  end
end