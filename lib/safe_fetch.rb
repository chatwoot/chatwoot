require 'ssrf_filter'

module SafeFetch
  DEFAULT_ALLOWED_CONTENT_TYPE_PREFIXES = %w[image/ video/].freeze
  DEFAULT_OPEN_TIMEOUT = 2
  DEFAULT_READ_TIMEOUT = 20
  DEFAULT_MAX_BYTES_FALLBACK_MB = 40

  Result = Data.define(:tempfile, :filename, :content_type) do
    def original_filename
      filename
    end
  end

  class Error < StandardError; end
  class InvalidUrlError < Error; end
  class UnsafeUrlError < Error; end
  class FetchError < Error; end
  class HttpError < Error; end
  class FileTooLargeError < Error; end
  class UnsupportedContentTypeError < Error; end

  def self.fetch(url,
                 max_bytes: nil,
                 allowed_content_type_prefixes: DEFAULT_ALLOWED_CONTENT_TYPE_PREFIXES,
                 allowed_content_types: [])
    raise ArgumentError, 'block required' unless block_given?

    effective_max_bytes = max_bytes || default_max_bytes
    filename = filename_for(parse_and_validate_url!(url))
    tempfile = Tempfile.new('chatwoot-safe-fetch', binmode: true)
    response = fetch_response(url, tempfile, effective_max_bytes, allowed_content_type_prefixes, allowed_content_types)
    yield build_result(tempfile, filename, response)
  rescue SsrfFilter::InvalidUriScheme, URI::InvalidURIError => e
    raise InvalidUrlError, e.message
  rescue SsrfFilter::Error, Resolv::ResolvError => e
    raise UnsafeUrlError, e.message
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, OpenSSL::SSL::SSLError => e
    raise FetchError, e.message
  ensure
    tempfile&.close!
  end

  class << self
    private

    def fetch_response(url, tempfile, max_bytes, allowed_content_type_prefixes, allowed_content_types)
      stream_to_tempfile(url, tempfile, max_bytes, allowed_content_type_prefixes, allowed_content_types)
    end

    def stream_to_tempfile(url, tempfile, max_bytes, allowed_content_type_prefixes, allowed_content_types)
      response = nil
      bytes_written = 0

      SsrfFilter.get(
        url,
        request_proc: ->(request) { apply_url_basic_auth(request) },
        http_options: { open_timeout: DEFAULT_OPEN_TIMEOUT, read_timeout: DEFAULT_READ_TIMEOUT }
      ) do |res|
        response = res
        next unless res.is_a?(Net::HTTPSuccess)

        unless allowed_content_type?(res['content-type'], allowed_content_type_prefixes, allowed_content_types)
          raise UnsupportedContentTypeError, "content-type not allowed: #{res['content-type']}"
        end

        res.read_body do |chunk|
          bytes_written += chunk.bytesize
          raise FileTooLargeError, "exceeded #{max_bytes} bytes" if bytes_written > max_bytes

          tempfile.write(chunk)
        end
      end

      response
    end

    def filename_for(uri)
      File.basename(uri.path).presence || "download-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
    end

    def build_result(tempfile, filename, response)
      raise HttpError, "#{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      tempfile.rewind
      content_type = normalized_content_type(response['content-type'])
      Result.new(tempfile: tempfile, filename: filename, content_type: content_type)
    end

    def default_max_bytes
      limit_mb = GlobalConfigService.load('MAXIMUM_FILE_UPLOAD_SIZE', DEFAULT_MAX_BYTES_FALLBACK_MB).to_i
      limit_mb = DEFAULT_MAX_BYTES_FALLBACK_MB if limit_mb <= 0
      limit_mb.megabytes
    end

    def parse_and_validate_url!(url)
      uri = URI.parse(url)
      raise InvalidUrlError, 'scheme must be http or https' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      raise InvalidUrlError, 'missing host' if uri.host.blank?

      uri
    end

    def allowed_content_type?(value, prefixes, content_types)
      mime = normalized_content_type(value)
      return false if mime.blank?

      prefixes.any? { |prefix| mime.start_with?(prefix) } || content_types.include?(mime)
    end

    def normalized_content_type(value)
      value.to_s.split(';').first&.strip&.downcase
    end

    def apply_url_basic_auth(request)
      uri = request.uri
      return if uri.user.blank?

      username = URI.decode_uri_component(uri.user)
      password = URI.decode_uri_component(uri.password.to_s)
      request.basic_auth(username, password)
    end
  end
end
