class Crawl4ai::MapService < Crawl4ai::BaseService
  base_uri ENV.fetch('CRAWL4AI_API_URL', 'https://api.crawl4ai.com/api/v1')

  def perform
    response = self.class.post(
      '/crawl',
      body: body.to_json,
      headers: headers
    )

    raise "Error fetching map: #{response.code} #{response.message}" unless response.success?

    parsed = response.parsed_response

    { links: parsed['results'][0]['links']['internal'].pluck('href') }
  end
end
