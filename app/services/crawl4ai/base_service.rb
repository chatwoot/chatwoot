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

  def headers
    {
      'Content-Type' => 'application/json'
      # 'Authorization' => "Bearer #{ENV.fetch('CRAWL4AI_API_KEY', nil)}"
    }
  end
end
