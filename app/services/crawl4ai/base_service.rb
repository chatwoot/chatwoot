require 'httparty'

class Crawl4ai::BaseService
  include HTTParty
  attr_reader :options

  def initialize(**options)
    @options = options
  end

  private

  def body
    {
      'urls' => options[:links],
      'crawler_config' => {
        'type' => 'CrawlerRunConfig',
        'params' => {
          'scraping_strategy' => {
            'type' => 'WebScrapingStrategy',
            'params' => {}
          },
          # 'exclude_domains' => get_domains,
          'exclude_external_links' => true,
          'exclude_social_media_links' => true,
          'exclude_all_images' => true,
          'exclude_external_images' => true,
          'stream' => true
        }
      }
    }
  end

  def get_domains # rubocop:disable Naming/AccessorMethodName
    options[:links].filter_map do |url|
      URI.parse(url).host
    rescue URI::InvalidURIError
      nil
    end.uniq
  end

  def headers
    {
      'Content-Type' => 'application/json'
      # 'Authorization' => "Bearer #{ENV.fetch('CRAWL4AI_API_KEY', nil)}"
    }
  end
end
