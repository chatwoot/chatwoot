# frozen_string_literal: true

module Aloo
  class WebScrapingService
    MAX_PAGES = 50
    MAX_DEPTH = 2
    REQUEST_TIMEOUT = 30

    attr_reader :base_url, :crawl_full_site, :visited_urls, :base_domain

    def initialize(url:, crawl_full_site: false)
      @base_url = url
      @crawl_full_site = crawl_full_site
      @visited_urls = Set.new
      @base_domain = extract_domain(url)
    end

    def perform
      pages = []
      errors = []

      if crawl_full_site
        crawl_site(base_url, pages, errors, 0)
      else
        result = fetch_and_parse(base_url)
        if result[:error]
          errors << { url: base_url, error: result[:error] }
        else
          pages << result
        end
      end

      { pages: pages, errors: errors }
    end

    private

    def crawl_site(url, pages, errors, depth)
      return if depth > MAX_DEPTH
      return if pages.size >= MAX_PAGES
      return if visited_urls.include?(url)

      visited_urls.add(url)

      result = fetch_and_parse(url)

      if result[:error]
        errors << { url: url, error: result[:error] }
        return
      end

      pages << result

      return unless crawl_full_site && depth < MAX_DEPTH

      result[:links].each do |link|
        break if pages.size >= MAX_PAGES

        crawl_site(link, pages, errors, depth + 1)
      end
    end

    def fetch_and_parse(url)
      response = HTTParty.get(url, timeout: REQUEST_TIMEOUT, follow_redirects: true)

      return { error: "HTTP #{response.code}" } unless response.success?

      doc = Nokogiri::HTML(response.body)
      title = extract_title(doc)
      content = extract_content(doc)
      links = extract_links(doc, url)

      {
        url: url,
        title: title,
        content: content,
        links: links
      }
    rescue HTTParty::Error, SocketError, Timeout::Error, Errno::ECONNREFUSED => e
      { error: e.message }
    rescue StandardError => e
      Rails.logger.error("[Aloo::WebScrapingService] Unexpected error fetching #{url}: #{e.message}")
      { error: e.message }
    end

    def extract_title(doc)
      title_element = doc.at_xpath('//title')
      title_element&.text&.strip || 'Untitled'
    end

    def extract_content(doc)
      # Remove unwanted elements
      %w[script style noscript nav header footer aside form iframe svg].each do |tag|
        doc.css(tag).remove
      end

      # Try to find main content area first
      main_content = doc.at_css('main, article, .content, .main-content, #content, #main')
      target = main_content || doc.at_css('body')

      return '' unless target

      # Convert to markdown for clean text extraction
      ReverseMarkdown.convert(target.to_html, unknown_tags: :bypass, github_flavored: true)
    rescue StandardError => e
      Rails.logger.error("[Aloo::WebScrapingService] Content extraction failed: #{e.message}")
      ''
    end

    def extract_links(doc, current_url)
      return [] unless crawl_full_site

      links = Set.new

      doc.css('a[href]').each do |anchor|
        href = anchor['href']
        next if href.blank? || href.start_with?('#', 'javascript:', 'mailto:', 'tel:')

        begin
          absolute_url = URI.join(current_url, href).to_s
          # Remove fragment
          absolute_url = absolute_url.split('#').first

          links.add(absolute_url) if same_domain?(absolute_url)
        rescue URI::InvalidURIError
          next
        end
      end

      links.to_a
    end

    def same_domain?(url)
      extract_domain(url) == base_domain
    rescue URI::InvalidURIError
      false
    end

    def extract_domain(url)
      uri = URI.parse(url)
      uri.host&.downcase&.gsub(/^www\./, '')
    rescue URI::InvalidURIError
      nil
    end
  end
end
