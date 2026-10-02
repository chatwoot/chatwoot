class Captain::Documents::SinglePageFetcher
  Result = Struct.new(:success, :title, :content, :error_code, keyword_init: true)

  CONTENT_MAX_LENGTH = 200_000
  TITLE_MAX_LENGTH = 255 # captain_documents.name is a varchar(255)

  def initialize(url)
    @url = url
  end

  def fetch
    page = WebCrawling::Factory.build.scrape(url: @url)
    validate_content(result_from(page))
  rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ETIMEDOUT
    Result.new(success: false, error_code: 'timeout')
  rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, OpenSSL::SSL::SSLError
    Result.new(success: false, error_code: 'fetch_failed')
  end

  private

  def result_from(page)
    error_code = page.error_code
    error_code ||= http_error_code(page.status_code) unless page.status_code.to_i.between?(200, 299)
    return Result.new(success: false, error_code: error_code) if error_code

    Result.new(
      success: true,
      title: page.title&.truncate(TITLE_MAX_LENGTH, omission: ''),
      content: page.markdown&.truncate(CONTENT_MAX_LENGTH, omission: '')
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
