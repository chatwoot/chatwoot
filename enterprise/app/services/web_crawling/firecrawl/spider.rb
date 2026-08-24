class WebCrawling::Firecrawl::Spider < WebCrawling::BaseSpider
  BASE_URL = 'https://api.firecrawl.dev/v2'.freeze
  MAX_DISCOVERY_DEPTH = 50

  def self.configured?
    WebCrawling::Firecrawl::Configuration.configured?
  end

  def initialize
    super
    @api_key = InstallationConfig.find_by!(name: WebCrawling::Firecrawl::Configuration::INSTALLATION_CONFIG_KEY).value
    raise 'Missing API key' if @api_key.blank?
  end

  def discover(url:, limit:, query: nil)
    options = { limit: limit }
    options[:search] = query if query.present?
    result = WebCrawling::Firecrawl::Configuration.client.map(url, ::Firecrawl::Models::MapOptions.new(**options))

    Array(result.links).filter_map do |link|
      next if link['url'].blank?

      WebCrawling::Types::DiscoveredPage.new(
        url: link['url'],
        title: link['title'],
        description: link['description']
      )
    end
  end

  def scrape(url:)
    response = request_scrape(url)
    return failed_page(url, response.code) unless response.success?

    normalize_scrape_response(url, response)
  end

  def scrape_many(urls:)
    job = WebCrawling::Firecrawl::Configuration.client.batch_scrape(
      urls,
      ::Firecrawl::Models::BatchScrapeOptions.new(options: WebCrawling::Firecrawl::Configuration.default_scrape_options)
    )

    Array(job.data).map { |document| normalize_document(document) }
  end

  def crawl(url:, limit:, callback_url: nil)
    raise ArgumentError, 'callback_url is required' if callback_url.blank?

    response = request_crawl(url, callback_url, limit)
    payload = response.parsed_response || {}

    WebCrawling::Types::CrawlSubmission.new(
      provider: :firecrawl,
      external_id: payload['id'],
      status: response.success? ? payload['status'].presence || 'queued' : 'failed',
      metadata: payload
    )
  end

  protected

  def request_crawl(url, webhook_url, crawl_limit = 10)
    HTTParty.post(
      "#{BASE_URL}/crawl",
      body: crawl_payload(url, webhook_url, crawl_limit),
      headers: headers
    )
  rescue StandardError => e
    raise "Failed to crawl URL: #{e.message}"
  end

  def request_scrape(url)
    HTTParty.post(
      "#{BASE_URL}/scrape",
      body: scrape_payload(url),
      headers: headers
    )
  end

  private

  def normalize_scrape_response(url, response)
    data = response.parsed_response&.dig('data')
    status_code = data&.dig('metadata', 'statusCode') || response.code

    WebCrawling::Types::Page.new(
      url: data&.dig('metadata', 'sourceURL').presence || data&.dig('metadata', 'url').presence || url,
      title: data&.dig('metadata', 'title'),
      markdown: data&.dig('markdown'),
      status_code: status_code,
      error_code: page_error_code(status_code, data&.dig('markdown'))
    )
  end

  def normalize_document(document)
    metadata = document&.metadata || {}
    status_code = metadata['statusCode']

    WebCrawling::Types::Page.new(
      url: metadata['sourceURL'] || metadata['url'],
      title: metadata['title'],
      markdown: document&.markdown,
      status_code: status_code,
      error_code: page_error_code(status_code, document&.markdown)
    )
  end

  def failed_page(url, status_code)
    WebCrawling::Types::Page.new(url: url, status_code: status_code, error_code: http_error_code(status_code))
  end

  def page_error_code(status_code, markdown)
    return http_error_code(status_code) if status_code.present? && !(200..299).cover?(status_code)
    return 'content_empty' if markdown.blank?

    nil
  end

  def http_error_code(status_code)
    case status_code
    when 404 then 'not_found'
    when 401, 403 then 'access_denied'
    when 408, 504 then 'timeout'
    else 'fetch_failed'
    end
  end

  def crawl_payload(url, webhook_url, crawl_limit)
    {
      url: url,
      maxDiscoveryDepth: MAX_DISCOVERY_DEPTH,
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
      excludeTags: WebCrawling::Firecrawl::Configuration::EXCLUDE_TAGS,
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
