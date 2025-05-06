require 'httparty'

class AiAgents::FirecrawlService
  include HTTParty
  base_uri ENV.fetch('FIRECRAWL_API_URL', 'https://api.firecrawl.dev/v1')

  class << self
    def map(url, limit: 30)
      response = post(
        '/map',
        body: { 'url' => url, 'limit' => limit }.to_json,
        headers: headers
      )
      raise "Error fetching map: #{response.code} #{response.message}" unless response.success?

      response.parsed_response
    end

    def scrape(url)
      response = post(
        '/scrape',
        body: { 'url' => url, 'formats' => ['markdown'] }.to_json,
        headers: headers
      )
      raise "Error fetching scrape: #{response.code} #{response.message}" unless response.success?

      parsed = response.parsed_response

      raise 'Scrape failed: Invalid response data' unless parsed['success'] && parsed['data']

      {
        url: parsed['data']['metadata']['url'],
        markdown: parsed['data']['markdown']
      }
    end

    def bulk_scrape(links)
      links.map do |link|
        Rails.logger.info("Start scraping link: #{link}")
        scrape = scrape(link)
        Rails.logger.info("Finished scraping link: #{link}")
        scrape
      rescue StandardError => e
        raise "Failed to scrape link #{link}: #{e.message}"
      end
    end

    private

    def headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{ENV.fetch('FIRECRAWL_API_KEY', nil)}"
      }
    end
  end
end
