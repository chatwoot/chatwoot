class Crawl4ai::CrawlService < Crawl4ai::BaseService
  base_uri ENV.fetch('CRAWL4AI_API_URL', 'https://api.crawl4ai.com/api/v1')

  def perform
    options[:links].map do |link|
      result = scrape(link)

      { url: link, markdown: result['results'][0]['markdown']['raw_markdown'] }
    rescue StandardError => e
      raise "Failed to scrape link #{link}: #{e.message}"
    end
  end

  private

  def scrape(url)
    Rails.logger.info("Start scraping link: #{link}")

    response = self.class.post(
      '/crawl',
      body: body(url).to_json,
      headers: headers
    )

    raise "Error fetching map: #{response.code} #{response.message}" unless response.success?

    Rails.logger.info("Finished scraping link: #{link}")

    response.parsed_response
  end

  def body(url)
    {
      'urls' => [url],
      'crawler_config' => {
        'type' => 'CrawlerRunConfig',
        'params' => {
          'scraping_strategy' => {
            'type' => 'WebScrapingStrategy',
            'params' => {}
          },
          'exclude_external_links' => true,
          'exclude_social_media_links' => true,
          'exclude_all_images' => true,
          'exclude_external_images' => true,
          'stream' => true
        }
      }
    }
  end
end
