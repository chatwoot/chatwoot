class Captain::Tools::SimplePageCrawlService
  attr_reader :external_link

  def initialize(external_link, exclude_paths: [])
    @external_link = external_link
    @exclude_matchers = build_exclude_matchers(exclude_paths)
    @doc = Nokogiri::HTML(HTTParty.get(external_link).body)
  end

  def page_links
    links = sitemap? ? extract_links_from_sitemap : extract_links_from_html
    filter_links(links)
  end

  def page_title
    title_element = @doc.at_xpath('//title')
    title_element&.text&.strip
  end

  def body_text_content
    ReverseMarkdown.convert @doc.at_xpath('//body'), unknown_tags: :bypass, github_flavored: true
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

  def excluded?(url)
    return false if @exclude_matchers.blank?

    path = extract_path(url)
    return false if path.blank?

    @exclude_matchers.any? { |matcher| matcher.match?(path) }
  end

  private

  def sitemap?
    @external_link.end_with?('.xml')
  end

  def filter_links(links)
    return links if @exclude_matchers.blank?

    links.each_with_object(Set.new) do |link, filtered|
      filtered << link unless excluded?(link)
    end
  end

  def extract_path(url)
    URI.parse(url).path.presence || '/'
  rescue URI::InvalidURIError
    nil
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

  def build_exclude_matchers(paths)
    Array(paths).compact_blank.map do |pattern|
      build_regex_from_pattern(pattern)
    rescue RegexpError
      nil
    end.compact
  end

  def build_regex_from_pattern(pattern)
    normalized = pattern.strip
    raise RegexpError if normalized.empty?

    if regex_pattern?(normalized)
      Regexp.new(normalized)
    else
      glob_pattern_to_regex(normalized)
    end
  end

  def regex_pattern?(pattern)
    pattern.start_with?('^') || pattern.end_with?('$')
  end

  def glob_pattern_to_regex(pattern)
    escaped = Regexp.escape(pattern).gsub('\*', '.*')
    Regexp.new(escaped)
  end
end
