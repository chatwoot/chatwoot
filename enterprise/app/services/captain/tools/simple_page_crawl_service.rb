class Captain::Tools::SimplePageCrawlService
  attr_reader :external_link, :status_code

  def initialize(external_link)
    @external_link = external_link
    @parser = Captain::Tools::HtmlPageParser.new(fetch_body)
    @doc = @parser.doc
  end

  def success?
    status_code.to_i.between?(200, 299)
  end

  def page_links
    sitemap? ? extract_links_from_sitemap : extract_links_from_html
  end

  def page_title
    @parser.title
  end

  def body_markdown
    @parser.body_markdown
  end

  def meta_description
    meta_desc = @doc.at_css('meta[name="description"]')
    return nil unless meta_desc && meta_desc['content']

    meta_desc['content'].strip
  end

  def favicon_url
    favicon_link = @doc.at_css('link[rel*="icon"]')
    return nil unless favicon_link && favicon_link['href']

    resolve_url(favicon_link['href'])
  end

  private

  def fetch_body
    body = ''
    SafeFetch.fetch(external_link, validate_content_type: false) do |result|
      body = result.tempfile.read
    end
    @status_code = 200
    body
  rescue SafeFetch::HttpError => e
    @status_code = e.message.to_i
    ''
  rescue SafeFetch::Error
    @status_code = nil
    ''
  end

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

  def resolve_url(url)
    return url if url.start_with?('http')

    URI.join(@external_link, url).to_s
  rescue StandardError
    url
  end
end
