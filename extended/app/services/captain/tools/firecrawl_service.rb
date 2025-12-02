require 'net/http'

class Captain::Tools::FirecrawlService
  API_ENDPOINT = 'https://api.firecrawl.dev/v1/crawl'.freeze

  def initialize
    @api_key = InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value
    raise ArgumentError, 'Firecrawl API key not configured' if @api_key.blank?
  end

  def perform(url, webhook_url, limit = 10)
    uri = URI(API_ENDPOINT)

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request.body = build_payload(url, webhook_url, limit)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_response(response)
  rescue StandardError => e
    Rails.logger.error("FirecrawlService Error: #{e.message}")
    raise e
  end

  private

  def build_payload(url, webhook_url, limit)
    {
      url: url,
      maxDepth: 50,
      ignoreSitemap: false,
      limit: limit,
      webhook: webhook_url,
      scrapeOptions: {
        onlyMainContent: false,
        formats: ['markdown'],
        excludeTags: ['iframe']
      }
    }.to_json
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      raise "Firecrawl API Error: #{response.code} - #{response.body}"
    end
  end
end
