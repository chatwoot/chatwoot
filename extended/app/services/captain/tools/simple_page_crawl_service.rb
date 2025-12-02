require 'net/http'
require 'nokogiri'
require 'reverse_markdown'

class Captain::Tools::SimplePageCrawlService
  attr_reader :url

  def initialize(url)
    @url = url
    @uri = URI(url)
    fetch_content
  end

  def page_links
    xml_sitemap? ? parse_sitemap_links : parse_html_links
  end

  def page_title
    @doc.at_xpath('//title')&.text&.strip
  end

  def body_text_content
    body = @doc.at_xpath('//body')
    return '' unless body

    ReverseMarkdown.convert(body, unknown_tags: :bypass, github_flavored: true)
  end

  def meta_description
    @doc.at_css('meta[name="description"]')&.[]('content')&.strip
  end

  def favicon_url
    link = @doc.at_css('link[rel*="icon"]')
    return nil unless link && link['href']

    absolute_url(link['href'])
  end

  private

  def fetch_content
    response = Net::HTTP.get_response(@uri)
    raise "Failed to fetch content: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    @doc = Nokogiri::HTML(response.body)
  end

  def xml_sitemap?
    @url.end_with?('.xml')
  end

  def parse_sitemap_links
    @doc.xpath('//loc').to_set(&:text)
  end

  def parse_html_links
    @doc.xpath('//a/@href').filter_map do |href|
      absolute_url(href.value)
    end.to_set
  end

  def absolute_url(href)
    return href if href.start_with?('http')

    URI.join(@url, href).to_s
  rescue URI::InvalidURIError
    nil
  end
end
