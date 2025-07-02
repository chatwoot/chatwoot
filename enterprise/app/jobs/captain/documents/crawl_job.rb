class Captain::Documents::CrawlJob < ApplicationJob
  queue_as :low

  def perform(document)
    if pdf_document?(document)
      perform_pdf_extraction(document)
    elsif InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value.present?
      perform_firecrawl_crawl(document)
    else
      perform_simple_crawl(document)
    end
  end

  def pdf_document?(document)
    return false if document.nil?

    pdf_by_metadata?(document) || pdf_by_url?(document)
  end

  private

  include Captain::FirecrawlHelper

  def pdf_by_metadata?(document)
    pdf_by_source_type?(document) || pdf_by_content_type?(document)
  rescue StandardError
    false
  end

  def pdf_by_source_type?(document)
    document.respond_to?(:source_type) && document.source_type == 'pdf_upload'
  end

  def pdf_by_content_type?(document)
    document.respond_to?(:content_type) && document.content_type&.include?('application/pdf')
  end

  def pdf_by_url?(document)
    return false if document.external_link.blank?

    url = document.external_link.downcase
    url.end_with?('.pdf') ||
      url.include?('/rails/active_storage/blobs/') ||
      (url.include?('blob') && url.include?('pdf'))
  end

  def perform_pdf_extraction(document)
    document.update(status: 'in_progress')

    pdf_extraction_service = Captain::Tools::PdfExtractionService.new(document.external_link)
    result = pdf_extraction_service.perform

    if result[:success] && result[:content].present?
      process_pdf_content_chunks(document, result[:content])
    else
      handle_pdf_extraction_failure(document, result)
    end
  rescue StandardError => e
    handle_pdf_extraction_error(document, e)
  end

  def perform_simple_crawl(document)
    page_links = Captain::Tools::SimplePageCrawlService.new(document.external_link).page_links

    page_links.each do |page_link|
      Captain::Tools::SimplePageCrawlParserJob.perform_later(
        assistant_id: document.assistant_id,
        page_link: page_link
      )
    end

    Captain::Tools::SimplePageCrawlParserJob.perform_later(
      assistant_id: document.assistant_id,
      page_link: document.external_link
    )
  end

  def perform_firecrawl_crawl(document)
    captain_usage_limits = document.account.usage_limits[:captain] || {}
    document_limit = captain_usage_limits[:documents] || {}
    crawl_limit = [document_limit[:current_available] || 10, 500].min

    Captain::Tools::FirecrawlService
      .new
      .perform(
        document.external_link,
        firecrawl_webhook_url(document),
        crawl_limit
      )
  end

  def firecrawl_webhook_url(document)
    webhook_url = Rails.application.routes.url_helpers.enterprise_webhooks_firecrawl_url

    "#{webhook_url}?assistant_id=#{document.assistant_id}&token=#{generate_firecrawl_token(document.assistant_id, document.account_id)}"
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
