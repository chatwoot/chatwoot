# frozen_string_literal: true

# Crawls a URL and extracts clean text content.
# Uses Firecrawl API if configured, otherwise falls back to a simple HTTP + Nokogiri scrape.
module Rag
  class UrlCrawler
    TIMEOUT = 30
    MAX_BODY_SIZE = 5.megabytes
    USER_AGENT = 'AirysChat-Bot/1.0'

    def initialize(firecrawl_api_key: nil)
      @firecrawl_api_key = firecrawl_api_key || InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value
    end

    # Crawls a URL and returns clean text content.
    def crawl(url)
      if @firecrawl_api_key.present?
        crawl_with_firecrawl(url)
      else
        crawl_with_nokogiri(url)
      end
    end

    private

    def crawl_with_firecrawl(url)
      uri = URI('https://api.firecrawl.dev/v1/scrape')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@firecrawl_api_key}"
      request['Content-Type'] = 'application/json'
      request.body = { url: url, formats: ['markdown'] }.to_json

      response = http.request(request)
      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      data.dig('data', 'markdown') || data.dig('data', 'content')
    end

    def crawl_with_nokogiri(url)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = TIMEOUT
      http.open_timeout = 10

      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = USER_AGENT

      response = http.request(request)
      return nil unless response.is_a?(Net::HTTPSuccess)
      return nil if response.body.bytesize > MAX_BODY_SIZE

      extract_text(response.body)
    end

    def extract_text(html)
      doc = Nokogiri::HTML(html)

      # Remove non-content elements
      doc.css('script, style, nav, header, footer, aside, iframe, noscript').remove

      # Extract main content area if available, otherwise body
      main = doc.at_css('main, article, [role="main"]') || doc.at_css('body')
      return nil unless main

      # Clean up whitespace
      text = main.text.gsub(/[ \t]+/, ' ').gsub(/\n{3,}/, "\n\n").strip
      text.presence
    end
  end
end
