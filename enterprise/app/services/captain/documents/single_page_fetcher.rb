class Captain::Documents::SinglePageFetcher
  Result = Struct.new(:success, :title, :content, :error_code, keyword_init: true)

  CONTENT_MAX_LENGTH = 200_000
  TITLE_MAX_LENGTH = 255 # captain_documents.name is a varchar(255)

  def initialize(url)
    @url = url
  end

  def fetch
    result = firecrawl_configured? ? fetch_with_firecrawl : fetch_with_fallback
    validate_content(result)
  rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ETIMEDOUT
    Result.new(success: false, error_code: 'timeout')
  rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, OpenSSL::SSL::SSLError
    Result.new(success: false, error_code: 'fetch_failed')
  end

  private

  def firecrawl_configured?
    Captain::Tools::FirecrawlService.configured?
  end

  def fetch_with_firecrawl
    response = Captain::Tools::FirecrawlService.new.scrape(@url)
    handle_firecrawl_response(response)
  end

  def handle_firecrawl_response(response)
    return Result.new(success: false, error_code: http_error_code(response.code)) unless response.success?

    data = response.parsed_response&.dig('data')
    target_error = firecrawl_target_error_code(data)
    return Result.new(success: false, error_code: target_error) if target_error

    Result.new(
      success: true,
      title: data&.dig('metadata', 'title')&.truncate(TITLE_MAX_LENGTH, omission: ''),
      content: data&.dig('markdown')&.truncate(CONTENT_MAX_LENGTH, omission: '')
    )
  end

  # Firecrawl returns API 200 even when the scraped page itself failed —
  # the target page's real status lives in data.metadata.statusCode.
  def firecrawl_target_error_code(data)
    status = data&.dig('metadata', 'statusCode')
    return nil if status.blank? || (200..299).cover?(status)

    http_error_code(status)
  end

  def fetch_with_fallback
    crawler = Captain::Tools::SimplePageCrawlService.new(@url)
    return Result.new(success: false, error_code: http_error_code(crawler.status_code)) unless crawler.success?

    Result.new(
      success: true,
      title: crawler.page_title&.truncate(TITLE_MAX_LENGTH, omission: ''),
      content: crawler.body_markdown&.truncate(CONTENT_MAX_LENGTH, omission: '')
    )
  end

  def validate_content(result)
    return result unless result.success && result.content.blank?

    Result.new(success: false, error_code: 'content_empty')
  end

  def http_error_code(status_code)
    case status_code
    when 404 then 'not_found'
    when 401, 403 then 'access_denied'
    when 408, 504 then 'timeout'
    else 'fetch_failed'
    end
  end
end
