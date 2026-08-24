class Captain::Documents::CrawlJob < ApplicationJob
  queue_as :low

  def perform(document)
    if document.pdf_document?
      perform_pdf_processing(document)
    else
      perform_web_crawl(document)
    end
  end

  private

  include Captain::FirecrawlHelper

  def perform_pdf_processing(document)
    Captain::Llm::PdfProcessingService.new(document).process
    document.update!(status: :available)
  rescue StandardError => e
    Rails.logger.error I18n.t('captain.documents.pdf_processing_failed', document_id: document.id, error: e.message)
    raise # Re-raise to let job framework handle retry logic
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

  def perform_web_crawl(document)
    provider = WebCrawling::Factory.configured_provider
    return perform_simple_crawl(document) if provider == :native

    spider = WebCrawling::Factory.build(provider: provider)

    captain_usage_limits = document.account.usage_limits[:captain] || {}
    document_limit = captain_usage_limits[:documents] || {}
    crawl_limit = [document_limit[:current_available] || 10, 500].min
    callback_url = callback_url_for(provider, document)
    submission = spider.crawl(url: document.external_link, callback_url: callback_url, limit: crawl_limit)

    store_context_dev_submission(document, submission) if submission.provider == :context_dev
  end

  def callback_url_for(provider, document)
    return firecrawl_webhook_url(document) if provider == :firecrawl

    Rails.application.routes.url_helpers.enterprise_webhooks_context_dev_url(document_id: document.id)
  end

  def store_context_dev_submission(document, submission)
    document.update!(
      web_crawling_provider: submission.provider,
      web_crawling_external_id: submission.external_id,
      web_crawling_webhook_secret: submission.metadata.fetch('webhook_secret')
    )
  end

  def firecrawl_webhook_url(document)
    webhook_url = Rails.application.routes.url_helpers.enterprise_webhooks_firecrawl_url

    "#{webhook_url}?assistant_id=#{document.assistant_id}&token=#{generate_firecrawl_token(document.assistant_id, document.account_id)}"
  end
end
