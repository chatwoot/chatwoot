class Crawl4ai::MapService < Crawl4ai::BaseService
  base_uri ENV.fetch('CRAWL4AI_API_URL', 'https://api.crawl4ai.com/api/v1')

  def perform
    response = self.class.post(
      '/crawl',
      body: body.to_json,
      headers: headers
    )

    raise "Error fetching map: #{response.code} #{response.message}" unless response.success?

    parsed = response.parsed_response
    links = parsed['results'][0]['links']['internal'].pluck('href')

    { links: clean_valid_html_links(links) }
  end

  private

  def clean_valid_html_links(links)
    valid_html_link?(links)
  end

  def valid_html_link?(links)
    http_links = filter_http_links(links)

    filtered_links = http_links.select do |link|
      link.start_with?('http')
      uri = URI.parse(link)

      uri.fragment.nil? &&
        (uri.path.match?(/\.html?$/i) || !uri.path.match?(/\.[a-z0-9]{2,5}$/i))
    end

    filtered_links.map do |link|
      link.gsub(%r{/[^/]+\.html/}, '/')
    end.uniq
  end

  def filter_http_links(links)
    links.select { |link| link.start_with?('http://', 'https://') }
  end
end
