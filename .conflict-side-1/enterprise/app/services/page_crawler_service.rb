class PageCrawlerService
  attr_reader :external_link

  def initialize(external_link)
    @external_link = external_link
    @doc = Nokogiri::HTML(HTTParty.get(external_link).body)
  end

  def page_links
    sitemap? ? extract_links_from_sitemap : extract_links_from_html
  end

  def page_title
    title_element = @doc.at_xpath('//title')
    title_element&.text&.strip
  end

  def body_text_content
    ReverseMarkdown.convert @doc.at_xpath('//body'), unknown_tags: :bypass, github_flavored: true
  end

  private

  def sitemap?
    @external_link.end_with?('.xml')
  end

  def extract_links_from_sitemap
    @doc.xpath('//loc').to_set(&:text)
  end

  def extract_links_from_html
    @doc.xpath('//a/@href').to_set do |link|
      absolute_url = URI.join(@external_link, link.value).to_s
      absolute_url
    end
  end
end
