module Firecrawl::Configuration
  INSTALLATION_CONFIG_KEY = WebCrawling::Firecrawl::Configuration::INSTALLATION_CONFIG_KEY
  EXCLUDE_TAGS = WebCrawling::Firecrawl::Configuration::EXCLUDE_TAGS
  DEFAULT_SCRAPE_MAX_AGE_MS = WebCrawling::Firecrawl::Configuration::DEFAULT_SCRAPE_MAX_AGE_MS

  module_function

  def configured?
    WebCrawling::Firecrawl::Configuration.configured?
  end

  def client
    WebCrawling::Firecrawl::Configuration.client
  end

  def api_key
    WebCrawling::Firecrawl::Configuration.api_key
  end

  def default_scrape_options(max_age: DEFAULT_SCRAPE_MAX_AGE_MS)
    WebCrawling::Firecrawl::Configuration.default_scrape_options(max_age: max_age)
  end
end
