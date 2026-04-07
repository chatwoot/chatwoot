require 'ssrf_filter'

module SafeFetch
  DEFAULT_MAX_BYTES = 10.megabytes
  DEFAULT_ALLOWED_CONTENT_TYPE_PREFIXES = %w[image/ video/].freeze
  DEFAULT_OPEN_TIMEOUT = 5
  DEFAULT_READ_TIMEOUT = 10

  Result = Struct.new(:tempfile, :filename, :content_type)

  class Error < StandardError; end
  class InvalidUrlError < Error; end
  class UnsafeUrlError < Error; end
  class FetchError < Error; end
  class HttpError < Error; end
  class FileTooLargeError < Error; end
  class UnsupportedContentTypeError < Error; end

  def self.fetch(url,
                 max_bytes: DEFAULT_MAX_BYTES,
                 allowed_content_type_prefixes: DEFAULT_ALLOWED_CONTENT_TYPE_PREFIXES)
    raise ArgumentError, 'block required' unless block_given?

    uri = parse_and_validate_url!(url)
    filename = File.basename(uri.path).presence || 'download'
    tempfile = Tempfile.new('chatwoot-safe-fetch', binmode: true)
    response = nil
    bytes_written = 0

    SsrfFilter.get(
      url,
      http_options: { open_timeout: DEFAULT_OPEN_TIMEOUT, read_timeout: DEFAULT_READ_TIMEOUT }
    ) do |res|
      response = res
      next unless res.is_a?(Net::HTTPSuccess)

      unless allowed_content_type?(res['content-type'], allowed_content_type_prefixes)
        raise UnsupportedContentTypeError, "content-type not allowed: #{res['content-type']}"
      end

      res.read_body do |chunk|
        bytes_written += chunk.bytesize
        raise FileTooLargeError, "exceeded #{max_bytes} bytes" if bytes_written > max_bytes

        tempfile.write(chunk)
      end
    end

    raise HttpError, "#{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    tempfile.rewind
    yield Result.new(tempfile: tempfile, filename: filename, content_type: response['content-type'])
  rescue SsrfFilter::InvalidUriScheme, URI::InvalidURIError => e
    raise InvalidUrlError, e.message
  rescue SsrfFilter::PrivateIPAddress, SsrfFilter::UnresolvedHostname, Resolv::ResolvError => e
    raise UnsafeUrlError, e.message
  rescue SsrfFilter::Error => e
    raise UnsafeUrlError, e.message
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, OpenSSL::SSL::SSLError => e
    raise FetchError, e.message
  ensure
    tempfile&.close!
  end

  class << self
    private

    def parse_and_validate_url!(url)
      uri = URI.parse(url)
      raise InvalidUrlError, 'scheme must be http or https' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      raise InvalidUrlError, 'missing host' if uri.host.blank?

      uri
    end

    def allowed_content_type?(value, prefixes)
      mime = value.to_s.split(';').first&.strip&.downcase
      return false if mime.blank?

      prefixes.any? { |prefix| mime.start_with?(prefix) }
    end
  end
end
