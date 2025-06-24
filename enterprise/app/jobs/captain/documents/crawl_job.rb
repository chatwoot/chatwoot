class Captain::Documents::CrawlJob < ApplicationJob
  queue_as :low

  def perform(document)
    case document.document_type
    when 'notion'
      perform_notion_crawl(document)
    when 'web'
      if InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value.present?
        perform_firecrawl_crawl(document)
      else
        perform_simple_crawl(document)
      end
    end
  end

  private

  include Captain::FirecrawlHelper

  def perform_notion_crawl(document)
    # external_id contains the Notion page ID for notion documents
    page_id = document.external_id
    crawler = Captain::Tools::NotionCrawlService.new(document.account, page_id)

    page_ids = crawler.page_ids

    page_ids.each do |notion_page_id|
      Captain::Tools::NotionCrawlParserJob.perform_later(
        assistant_id: document.assistant_id,
        page_id: notion_page_id
      )
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
