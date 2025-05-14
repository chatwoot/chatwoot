class Crawl4ai::CrawlService < Crawl4ai::BaseService
  base_uri ENV.fetch('CRAWL4AI_API_URL', 'https://api.crawl4ai.com/api/v1')

  def perform
    options[:links].map do |link|
      Rails.logger.info("Start scraping link: #{link}")
      result = scrape(link)
      Rails.logger.info("Finished scraping link: #{link}")
      { url: link, markdown: result['results'][0]['markdown']['raw_markdown'] }
    rescue StandardError => e
      raise "Failed to scrape link #{link}: #{e.message}"
    end
  end

  private

  def scrape(url)
    response = self.class.post(
      '/crawl',
      body: body(url).to_json,
      headers: headers
    )

    raise "Error fetching map: #{response.code} #{response.message}" unless response.success?

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
          'exclude_social_media_domains' => [
            'facebook.com',
            'twitter.com',
            'x.com',
            'linkedin.com',
            'instagram.com',
            'pinterest.com',
            'tiktok.com',
            'snapchat.com',
            'reddit.com'
          ],
          'stream' => true
        }
      }
    }
  end
end
