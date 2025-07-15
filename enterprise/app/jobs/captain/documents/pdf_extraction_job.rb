class Captain::Documents::PdfExtractionJob < ApplicationJob
  retry_on ActiveStorage::FileNotFoundError, attempts: 3, wait: 2.seconds
  retry_on Faraday::BadRequestError, attempts: 3, wait: 2.seconds

  queue_as :low

  # This job runs in parallel with S3 upload
  # ActiveStorage handles S3 upload asynchronously
  # We process the PDF independently

  def perform(document)
    return unless document.pdf_document?

    initialize_document_processing(document)
    result = extract_pdf_content(document)
    process_extraction_result(document, result)
  rescue StandardError => e
    handle_extraction_failure(document, e)
  end

  private

  def initialize_document_processing(document)
    document.update(status: 'in_progress')
  end

  def extract_pdf_content(document)
    pdf_source = document.file

    # Always use OpenAI direct PDF processing
    pdf_service = Captain::Tools::PdfOpenaiService.new(pdf_source)
    pdf_service.perform
  end

  def process_extraction_result(document, result)
    if result[:success] && result[:content].present?
      process_pdf_content(document, result[:content])
    else
      handle_pdf_extraction_failure(document, result)
    end
  end

  def process_pdf_content(document, content)
    # Content is an array with single item for direct PDF processing
    pdf_data = content.first || {}
    metadata = pdf_data[:metadata]

    if metadata && metadata[:processing_type] == 'direct_pdf'
      process_direct_pdf_content(document, metadata)
    else
      document.update!(
        content: pdf_data[:content] || '',
        status: 'available'
      )
    end
  end

  def process_direct_pdf_content(document, metadata)
    # Store the OpenAI file_id in the document
    document.update!(
      content: metadata[:openai_file_id],
      status: 'available'
    )

    # Process the PDF directly
    document.responses.destroy_all
    Captain::Documents::ResponseBuilderJob.perform_later(
      document,
      metadata[:openai_file_id],
      skip_reset: false,
      metadata: metadata
    )
  end

  def handle_pdf_extraction_failure(document, _result)
    document.update(status: 'available')
  end

  def handle_extraction_failure(document, _error)
    document.update(status: 'available')
  end
end