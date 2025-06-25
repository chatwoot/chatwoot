class Captain::Documents::CrawlJob < ApplicationJob
  queue_as :low

  def perform(document)
    if InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value.present?
      perform_firecrawl_crawl(document)
    else
      if pdf_document?(document)
        perform_pdf_extraction(document)
      else
        perform_simple_crawl(document)
      end
    end
  end

  private

  include Captain::FirecrawlHelper

  def pdf_document?(document)
    # Check if the document source is a PDF
    document.external_link&.downcase&.end_with?('.pdf') ||
      document.content_type&.include?('application/pdf') ||
      document.source_type == 'pdf_upload'
  end

  def perform_pdf_extraction(document)
    begin
      # Mark document as in progress
      document.update(status: 'in_progress')

      pdf_extraction_service = Captain::Tools::PdfExtractionService.new(document.external_link)
      result = pdf_extraction_service.perform

      if result[:success] && result[:content].present?
        # Process content in chunks similar to web crawling
        result[:content].each do |content_chunk|
          Captain::Tools::PdfExtractionParserJob.perform_later(
            assistant_id: document.assistant_id,
            pdf_content: content_chunk,
            document_id: document.id
          )
        end

        # Update document status to indicate processing has started
        document.update(status: 'in_progress', processed_at: nil)
      else
        # Handle extraction failure - mark as available but log error
        error_message = result[:errors]&.join(', ') || 'Failed to extract text from PDF'
        document.update(status: 'available')
        Rails.logger.error "PDF extraction failed for document #{document.id}: #{error_message}"
      end
    rescue StandardError => e
      # Handle errors gracefully - mark as available but log error
      Rails.logger.error "PDF extraction failed for document #{document.id}: #{e.message}"
      document.update(status: 'available')
    end
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
end
