class SafeFetch::Fetcher
  def initialize(options)
    @options = options
  end

  def fetch
    with_tempfile do |tempfile|
      response = stream_response(tempfile)
      raise SafeFetch::HttpError, "#{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      tempfile.rewind
      yield SafeFetch::Result.new(
        tempfile: tempfile,
        filename: options.filename,
        content_type: normalized_content_type(response['content-type'])
      )
    end
  end

  private

  attr_reader :options

  def with_tempfile
    tempfile = Tempfile.new('chatwoot-safe-fetch', binmode: true)
    yield tempfile
  ensure
    tempfile&.close!
  end

  def stream_response(tempfile)
    response = nil
    bytes_written = 0

    SsrfFilter.public_send(options.method, options.url, **options.request_options) do |res|
      response = res
      next unless res.is_a?(Net::HTTPSuccess)

      validate_content_type!(res['content-type'])
      bytes_written = write_response_body(res, tempfile, bytes_written)
    end

    response
  end

  def validate_content_type!(content_type)
    return unless options.validate_content_type?
    return if allowed_content_type?(content_type)

    raise SafeFetch::UnsupportedContentTypeError, "content-type not allowed: #{content_type}"
  end

  def write_response_body(response, tempfile, bytes_written)
    response.read_body do |chunk|
      bytes_written += chunk.bytesize
      raise SafeFetch::FileTooLargeError, "exceeded #{options.effective_max_bytes} bytes" if bytes_written > options.effective_max_bytes

      tempfile.write(chunk)
    end

    bytes_written
  end

  def allowed_content_type?(value)
    mime = normalized_content_type(value)
    return false if mime.blank?

    options.allowed_content_type_prefixes.any? { |prefix| mime.start_with?(prefix) } ||
      options.allowed_content_types.include?(mime)
  end

  def normalized_content_type(value)
    value.to_s.split(';').first&.strip&.downcase
  end
end
