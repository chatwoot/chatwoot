class Captain::Tools::FirecrawlService
  def initialize
    @api_key = InstallationConfig.find_by!(name: 'CAPTAIN_FIRECRAWL_API_KEY').value
    raise 'Missing API key' if @api_key.empty?
  end

  def perform(url, webhook_url, crawl_limit = 10, exclude_paths: [])
    HTTParty.post(
      'https://api.firecrawl.dev/v1/crawl',
      body: crawl_payload(url, webhook_url, crawl_limit, exclude_paths),
      headers: headers
    )
  rescue StandardError => e
    raise "Failed to crawl URL: #{e.message}"
  end

  private

  def crawl_payload(url, webhook_url, crawl_limit, exclude_paths)
    {
      url: url,
      maxDepth: 50,
      ignoreSitemap: false,
      limit: crawl_limit,
      webhook: webhook_url,
      excludePaths: Array(exclude_paths),
      scrapeOptions: {
        onlyMainContent: false,
        formats: ['markdown'],
        excludeTags: ['iframe']
      }
    }.to_json
  end

  def headers
    {
      'Authorization' => "Bearer #{@api_key}",
      'Content-Type' => 'application/json'
    }
  end
end
