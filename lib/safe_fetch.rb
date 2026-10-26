require 'ssrf_filter'

module SafeFetch
  DEFAULT_ALLOWED_CONTENT_TYPE_PREFIXES = %w[image/ video/].freeze
  DEFAULT_ALLOWED_CONTENT_TYPES = [].freeze
  DEFAULT_SENSITIVE_HEADERS = %w[authorization cookie proxy-authorization].freeze
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
  class UnsupportedMethodError < Error; end

  def self.fetch(url, **, &)
    raise ArgumentError, 'block required' unless block_given?

    SafeFetch::Fetcher.new(SafeFetch::RequestOptions.new(url: url, **)).fetch(&)
  rescue SsrfFilter::InvalidUriScheme, URI::InvalidURIError => e
    raise InvalidUrlError, e.message
  rescue SsrfFilter::Error, Resolv::ResolvError => e
    raise UnsafeUrlError, e.message
  end

  # Returns an address of the hostname that is safe to connect to.
  # ssrf_filter keeps its address check private, but it is the same check SafeFetch.fetch applies.
  def self.safe_address(hostname)
    addresses = SsrfFilter::DEFAULT_RESOLVER.call(hostname)
    addresses = addresses.reject { |address| SsrfFilter.send(:unsafe_ip_address?, address) } unless allow_private_network?
    addresses.sample || raise(UnsafeUrlError, "#{hostname} does not resolve to a public address")
  end

  def self.allow_private_network?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('SAFE_FETCH_ALLOW_PRIVATE_NETWORK', false))
  end
end
