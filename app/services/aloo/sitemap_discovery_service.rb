# frozen_string_literal: true

module Aloo
  class SitemapDiscoveryService
    MAX_PAGES = 100
    REQUEST_TIMEOUT = 15
    IMPORTANT_PATH_PATTERNS = %w[
      / /about /features /pricing /contact /faq /help
      /docs /documentation /support /services /products
    ].freeze

    attr_reader :base_url, :base_domain, :discovered_pages

    def initialize(url)
      @base_url = normalize_url(url)
      @base_domain = extract_domain(@base_url)
      @discovered_pages = []
      @visited_urls = Set.new
    end

    # Discover pages from sitemap or by crawling
    # Returns array of { url:, title:, important: }
    def discover
      # Try sitemap first
      pages = discover_from_sitemap

      # Fall back to link discovery if sitemap fails or is empty
      pages = discover_from_links if pages.empty?

      # Sort: important pages first, then alphabetically
      pages.sort_by { |p| [p[:important] ? 0 : 1, p[:url]] }
           .take(MAX_PAGES)
    end

    private

    def discover_from_sitemap
      sitemap_urls = [
        "#{base_url}/sitemap.xml",
        "#{base_url}/sitemap_index.xml",
        "#{base_url}/sitemap.xml.gz"
      ]

      sitemap_urls.each do |sitemap_url|
        pages = fetch_sitemap(sitemap_url)
        return pages if pages.any?
      end

      []
    rescue StandardError => e
      Rails.logger.debug { "[Aloo::SitemapDiscoveryService] Sitemap discovery failed: #{e.message}" }
      []
    end

    def fetch_sitemap(sitemap_url)
      response = HTTParty.get(sitemap_url, timeout: REQUEST_TIMEOUT, follow_redirects: true)
      return [] unless response.success?

      content = response.body
      # Handle gzipped content
      content = Zlib::GzipReader.new(StringIO.new(content)).read if sitemap_url.end_with?('.gz')

      parse_sitemap(content)
    rescue HTTParty::Error, SocketError, Timeout::Error, Errno::ECONNREFUSED, Zlib::Error
      []
    end

    def parse_sitemap(content)
      doc = Nokogiri::XML(content)
      pages = []

      # Check if it's a sitemap index
      sitemap_locs = doc.xpath('//xmlns:sitemap/xmlns:loc', 'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9')
      if sitemap_locs.any?
        # Recursively fetch nested sitemaps (limit to 5)
        sitemap_locs.take(5).each do |loc|
          nested_pages = fetch_sitemap(loc.text)
          pages.concat(nested_pages)
          break if pages.size >= MAX_PAGES
        end
        return pages
      end

      # Parse regular sitemap
      url_elements = doc.xpath('//xmlns:url/xmlns:loc', 'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9')
      url_elements = doc.xpath('//url/loc') if url_elements.empty?

      url_elements.each do |loc|
        url = loc.text.strip
        next unless same_domain?(url)
        next if @visited_urls.include?(url)

        @visited_urls.add(url)
        pages << build_page_entry(url)
        break if pages.size >= MAX_PAGES
      end

      pages
    end

    def discover_from_links
      pages = []

      # Start with the base URL
      homepage = fetch_page_info(base_url)
      pages << homepage if homepage

      # Extract links from the homepage
      response = HTTParty.get(base_url, timeout: REQUEST_TIMEOUT, follow_redirects: true)
      return pages unless response.success?

      doc = Nokogiri::HTML(response.body)
      links = extract_internal_links(doc)

      links.each do |url|
        next if @visited_urls.include?(url)

        @visited_urls.add(url)
        page_entry = build_page_entry(url)

        # Try to get title from meta tags for important pages
        if page_entry[:important]
          page_info = fetch_page_info(url)
          page_entry = page_info if page_info
        end

        pages << page_entry
        break if pages.size >= MAX_PAGES
      end

      pages
    rescue HTTParty::Error, SocketError, Timeout::Error
      pages
    end

    def extract_internal_links(doc)
      links = Set.new

      doc.css('a[href]').each do |anchor|
        href = anchor['href']
        next if href.blank? || href.start_with?('#', 'javascript:', 'mailto:', 'tel:')

        begin
          absolute_url = URI.join(base_url, href).to_s.split('#').first
          links.add(absolute_url) if same_domain?(absolute_url)
        rescue URI::InvalidURIError
          next
        end
      end

      # Prioritize important pages
      links.to_a.sort_by do |url|
        path = URI.parse(url).path.downcase
        important_index = IMPORTANT_PATH_PATTERNS.index { |p| path == p || path == "#{p}/" }
        important_index || 999
      end
    end

    def fetch_page_info(url)
      response = HTTParty.get(url, timeout: REQUEST_TIMEOUT, follow_redirects: true)
      return nil unless response.success?

      doc = Nokogiri::HTML(response.body)
      title = doc.at_xpath('//title')&.text&.strip || extract_title_from_url(url)

      {
        url: url,
        title: title.truncate(100),
        important: important_page?(url)
      }
    rescue StandardError
      build_page_entry(url)
    end

    def build_page_entry(url)
      {
        url: url,
        title: extract_title_from_url(url),
        important: important_page?(url)
      }
    end

    def extract_title_from_url(url)
      uri = URI.parse(url)
      path = uri.path.gsub(%r{^/|/$}, '')

      return uri.host if path.blank?

      # Convert path to readable title
      path.split('/').last&.gsub(/[-_]/, ' ')&.titleize || uri.host
    rescue URI::InvalidURIError
      'Page'
    end

    def important_page?(url)
      uri = URI.parse(url)
      path = uri.path.downcase

      IMPORTANT_PATH_PATTERNS.any? { |p| path == p || path == "#{p}/" }
    rescue URI::InvalidURIError
      false
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

    def normalize_url(url)
      url = "https://#{url}" unless url.match?(%r{^https?://})
      uri = URI.parse(url)
      # Ensure base URL has no trailing slash
      "#{uri.scheme}://#{uri.host}#{uri.path.gsub(%r{/+$}, '')}"
    rescue URI::InvalidURIError
      url
    end
  end
end
