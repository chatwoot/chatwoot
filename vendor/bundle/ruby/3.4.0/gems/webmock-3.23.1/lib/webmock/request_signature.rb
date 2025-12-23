# frozen_string_literal: true

module WebMock

  class RequestSignature

    attr_accessor :method, :uri, :body
    attr_reader :headers

    def initialize(method, uri, options = {})
      self.method = method.to_sym
      self.uri = uri.is_a?(Addressable::URI) ? uri : WebMock::Util::URI.normalize_uri(uri)
      assign_options(options)
    end

    def to_s
      string = "#{self.method.to_s.upcase}".dup
      string << " #{WebMock::Util::URI.strip_default_port_from_uri_string(self.uri.to_s)}"
      string << " with body '#{body.to_s}'" if body && body.to_s != ''
      if headers && !headers.empty?
        string << " with headers #{WebMock::Util::Headers.sorted_headers_string(headers)}"
      end
      string
    end

    def headers=(headers)
      @headers = WebMock::Util::Headers.normalize_headers(headers)
    end

    def hash
      self.to_s.hash
    end

    def eql?(other)
      self.to_s == other.to_s
    end
    alias == eql?

    def url_encoded?
      !!(headers&.fetch('Content-Type', nil)&.start_with?('application/x-www-form-urlencoded'))
    end

    def json_headers?
      !!(headers&.fetch('Content-Type', nil)&.start_with?('application/json'))
    end

    private

    def assign_options(options)
      self.body = options[:body] if options.has_key?(:body)
      self.headers = options[:headers] if options.has_key?(:headers)
    end

  end

end
