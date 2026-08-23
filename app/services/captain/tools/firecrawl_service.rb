class Captain::Tools::FirecrawlService
  BASE_URL = 'https://api.firecrawl.dev/v2'.freeze
  FIRECRAWL_EXCLUDE_TAGS = %w[iframe .sidebar .cookie-banner [role=navigation] [role=banner] [role=contentinfo]].freeze

  def self.configured?
    Llm::Config.firecrawl_api_key.present?
  end

  def initialize
    @api_key = Llm::Config.firecrawl_api_key
    return if @api_key.present?

    error = 'Missing API key'
    Captain::Llm::FailureLogger.record(source: :firecrawl, error: error)
    raise error
  end

  def perform(url, webhook_url, crawl_limit = 10)
    response = HTTParty.post(
      "#{BASE_URL}/crawl",
      body: crawl_payload(url, webhook_url, crawl_limit),
      headers: headers
    )

    raise_non_success!(response, url)
    response
  rescue StandardError => e
    Captain::Llm::FailureLogger.record(source: :firecrawl, error: "Failed to crawl URL: #{e.message}")
    raise "Failed to crawl URL: #{e.message}"
  end

  def scrape(url)
    response = HTTParty.post(
      "#{BASE_URL}/scrape",
      body: scrape_payload(url),
      headers: headers
    )

    raise_non_success!(response, url)
    response
  rescue StandardError => e
    Captain::Llm::FailureLogger.record(source: :firecrawl, error: "Failed to scrape URL: #{e.message}")
    raise "Failed to scrape URL: #{e.message}"
  end

  private

  # HTTParty does not raise on non-2xx responses, so a rejected key or failed
  # crawl returns a plain response object instead of an exception. Surface it as
  # a raise so failures (wrong key / bad URL) are logged and the job fails loudly
  # instead of silently continuing.
  def raise_non_success!(response, url)
    return if response.success?

    raise "Firecrawl returned HTTP #{response.code} for #{url}: #{response.body.to_s[0, 300]}"
  end

  def crawl_payload(url, webhook_url, crawl_limit)
    {
      url: url,
      maxDiscoveryDepth: 50,
      sitemap: 'include',
      limit: crawl_limit,
      webhook: { url: webhook_url },
      scrapeOptions: scrape_options
    }.to_json
  end

  def scrape_payload(url)
    { url: url }.merge(scrape_options).to_json
  end

  def scrape_options
    {
      onlyMainContent: true,
      formats: ['markdown'],
      excludeTags: FIRECRAWL_EXCLUDE_TAGS,
      maxAge: 0
    }
  end

  def headers
    {
      'Authorization' => "Bearer #{@api_key}",
      'Content-Type' => 'application/json'
    }
  end
end
