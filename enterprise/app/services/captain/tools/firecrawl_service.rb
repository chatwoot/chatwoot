class Captain::Tools::FirecrawlService < WebCrawling::Firecrawl::Spider
  BASE_URL = WebCrawling::Firecrawl::Spider::BASE_URL
  FIRECRAWL_EXCLUDE_TAGS = WebCrawling::Firecrawl::Configuration::EXCLUDE_TAGS

  def perform(url, webhook_url, crawl_limit = 10)
    request_crawl(url, webhook_url, crawl_limit)
  end

  def scrape(url)
    request_scrape(url)
  end
end
