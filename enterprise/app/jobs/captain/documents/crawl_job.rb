class Captain::Documents::CrawlJob < ApplicationJob
  queue_as :low

  def perform(document)
    if InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY').present?
      perform_firecrawl_crawl(document)
    else
      perform_simple_crawl(document)
    end
  end

  private

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
    webhook_url = Rails.application.routes.url_helpers.enterprise_webhooks_firecrawl_url

    Captain::Tools::FirecrawlService
      .new
      .perform(
        document.external_link,
        "#{webhook_url}?assistant_id=#{document.assistant_id}"
      )
  end
end
