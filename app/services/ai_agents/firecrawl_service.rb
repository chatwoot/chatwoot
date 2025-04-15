require 'httparty'

class AiAgents::FirecrawlService
  include HTTParty
  base_uri 'https://api.firecrawl.dev/v1'

  class << self
    def map(url, limit: 5)
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

      return unless parsed['success'] && parsed['data']

      {
        url: parsed['data']['metadata']['url'],
        markdown: parsed['data']['markdown']
      }
    end

    def bulk_scrape(links)
      links.map do |link|
        scrape(link)
      rescue StandardError => e
        Rails.logger.error("Error scraping link #{link}: #{e.message}")
        nil
      end
    end

    private

    def headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => 'Bearer fc-4274d1931e3042e6a300574b2722bf61'
      }
    end
  end
end
