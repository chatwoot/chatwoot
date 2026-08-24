class WebCrawling::ContextDev::Spider < WebCrawling::BaseSpider
  MAX_CRAWL_DEPTH = 50
  RESULT_PAGE_LIMIT = 100

  def self.configured?
    WebCrawling::ContextDev::Configuration.configured?
  end

  def initialize
    super
    @api_key = InstallationConfig.find_by!(name: WebCrawling::ContextDev::Configuration::INSTALLATION_CONFIG_KEY).value
    raise 'Missing API key' if @api_key.blank?
  end

  def discover(url:, limit:, query: nil)
    params = { domain: domain_for(url), maxLinks: limit }
    params[:search] = query if query.present?
    response = get('/web/scrape/sitemap', query: params)
    ensure_success!(response)

    Array(response.parsed_response['urls']).map do |page_url|
      WebCrawling::Types::DiscoveredPage.new(url: page_url)
    end
  end

  def scrape(url:)
    response = get(
      '/web/scrape/markdown',
      query: { url: url, useMainContentOnly: true, maxAgeMs: 0 }
    )
    return failed_page(url, response) unless response.success?

    payload = response.parsed_response
    metadata = payload['metadata'] || {}

    WebCrawling::Types::Page.new(
      url: metadata['finalUrl'].presence || payload['url'].presence || url,
      title: metadata['title'],
      markdown: payload['markdown'],
      status_code: response.code,
      error_code: payload['markdown'].blank? ? 'content_empty' : nil
    )
  end

  def crawl(url:, limit:, callback_url: nil)
    raise ArgumentError, 'callback_url is required' if callback_url.blank?

    response = post('/batch/submit', body: crawl_payload(url, limit, callback_url))
    ensure_success!(response)
    payload = response.parsed_response

    WebCrawling::Types::CrawlSubmission.new(
      provider: :context_dev,
      external_id: payload['id'],
      status: payload['status'],
      metadata: payload
    )
  end

  def fetch_results(batch_id:, cursor: nil, limit: RESULT_PAGE_LIMIT)
    params = { limit: limit }
    params[:cursor] = cursor if cursor.present?
    response = get("/batch/#{batch_id}/results", query: params)
    ensure_success!(response)
    payload = response.parsed_response

    WebCrawling::Types::BatchResults.new(
      pages: Array(payload['data']).map { |record| normalize_batch_record(record) },
      has_more: payload['has_more'],
      next_cursor: payload['next_cursor']
    )
  end

  def batch_status(batch_id:)
    response = get("/batch/#{batch_id}", query: {})
    ensure_success!(response)
    response.parsed_response.fetch('status')
  end

  private

  def domain_for(url)
    URI.parse(url).host || url
  end

  def normalize_batch_record(record)
    metadata = record['metadata'] || {}
    status_code = record['http_status']

    WebCrawling::Types::Page.new(
      url: record['final_url'].presence || record['url'],
      title: metadata['title'],
      markdown: record['markdown'],
      status_code: status_code,
      error_code: batch_error_code(record, status_code)
    )
  end

  def batch_error_code(record, status_code)
    return nil if record['status'] == 'ok' && record['markdown'].present?
    return 'content_empty' if record['status'] == 'ok'

    context_error_code(record['error_code'], status_code)
  end

  def failed_page(url, response)
    payload = response.parsed_response || {}
    WebCrawling::Types::Page.new(
      url: url,
      status_code: response.code,
      error_code: context_error_code(payload['error_code'], response.code)
    )
  end

  def context_error_code(error_code, status_code)
    case error_code
    when 'NOT_FOUND' then 'not_found'
    when 'UNAUTHORIZED', 'FORBIDDEN' then 'access_denied'
    when 'REQUEST_TIMEOUT' then 'timeout'
    else http_error_code(status_code)
    end
  end

  def http_error_code(status_code)
    case status_code
    when 404 then 'not_found'
    when 401, 403 then 'access_denied'
    when 408, 504 then 'timeout'
    else 'fetch_failed'
    end
  end

  def ensure_success!(response)
    return if response.success?

    message = response.parsed_response&.dig('message') || "HTTP #{response.code}"
    raise "Context.dev request failed: #{message}"
  end

  def crawl_payload(url, limit, callback_url)
    {
      input: {
        mode: 'crawl',
        data: {
          format: 'markdown',
          source: {
            type: 'start_url',
            url: url,
            controls: {
              maxUrls: limit,
              maxDepth: MAX_CRAWL_DEPTH,
              followSubdomains: false
            }
          },
          options: { useMainContentOnly: true }
        }
      },
      webhookUrl: callback_url
    }.to_json
  end

  def get(path, query:)
    HTTParty.get("#{WebCrawling::ContextDev::Configuration::BASE_URL}#{path}", query: query, headers: headers)
  end

  def post(path, body:)
    HTTParty.post("#{WebCrawling::ContextDev::Configuration::BASE_URL}#{path}", body: body, headers: headers)
  end

  def headers
    {
      'Authorization' => "Bearer #{@api_key}",
      'Content-Type' => 'application/json'
    }
  end
end
