class Captain::Documents::CrawlJob < ApplicationJob
  queue_as :low

  def perform(document)
    if InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value.present?
      perform_firecrawl_crawl(document)
    else
      perform_simple_crawl(document)
    end
  end

  private

  include Captain::FirecrawlHelper

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
