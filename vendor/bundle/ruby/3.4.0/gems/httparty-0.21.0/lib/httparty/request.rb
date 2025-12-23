# frozen_string_literal: true

require 'erb'

module HTTParty
  class Request #:nodoc:
    SupportedHTTPMethods = [
      Net::HTTP::Get,
      Net::HTTP::Post,
      Net::HTTP::Patch,
      Net::HTTP::Put,
      Net::HTTP::Delete,
      Net::HTTP::Head,
      Net::HTTP::Options,
      Net::HTTP::Move,
      Net::HTTP::Copy,
      Net::HTTP::Mkcol,
      Net::HTTP::Lock,
      Net::HTTP::Unlock,
    ]

    SupportedURISchemes  = ['http', 'https', 'webcal', nil]

    NON_RAILS_QUERY_STRING_NORMALIZER = proc do |query|
      Array(query).sort_by { |a| a[0].to_s }.map do |key, value|
        if value.nil?
          key.to_s
        elsif value.respond_to?(:to_ary)
          value.to_ary.map {|v| "#{key}=#{ERB::Util.url_encode(v.to_s)}"}
        else
          HashConversions.to_params(key => value)
        end
      end.flatten.join('&')
    end

    JSON_API_QUERY_STRING_NORMALIZER = proc do |query|
      Array(query).sort_by { |a| a[0].to_s }.map do |key, value|
        if value.nil?
          key.to_s
        elsif value.respond_to?(:to_ary)
          values = value.to_ary.map{|v| ERB::Util.url_encode(v.to_s)}
          "#{key}=#{values.join(',')}"
        else
          HashConversions.to_params(key => value)
        end
      end.flatten.join('&')
    end

    def self._load(data)
      http_method, path, options, last_response, last_uri, raw_request = Marshal.load(data)
      instance = new(http_method, path, options)
      instance.last_response = last_response
      instance.last_uri = last_uri
      instance.instance_variable_set("@raw_request", raw_request)
      instance
    end

    attr_accessor :http_method, :options, :last_response, :redirect, :last_uri
    attr_reader :path

    def initialize(http_method, path, o = {})
      @changed_hosts = false
      @credentials_sent = false

      self.http_method = http_method
      self.options = {
        limit: o.delete(:no_follow) ? 1 : 5,
        assume_utf16_is_big_endian: true,
        default_params: {},
        follow_redirects: true,
        parser: Parser,
        uri_adapter: URI,
        connection_adapter: ConnectionAdapter
      }.merge(o)
      self.path = path
      set_basic_auth_from_uri
    end

    def path=(uri)
      uri_adapter = options[:uri_adapter]

      @path = if uri.is_a?(uri_adapter)
        uri
      elsif String.try_convert(uri)
        uri_adapter.parse(uri).normalize
      else
        raise ArgumentError,
          "bad argument (expected #{uri_adapter} object or URI string)"
      end
    end

    def request_uri(uri)
      if uri.respond_to? :request_uri
        uri.request_uri
      else
        uri.path
      end
    end

    def uri
      if redirect && path.relative? && path.path[0] != '/'
        last_uri_host = @last_uri.path.gsub(/[^\/]+$/, '')

        path.path = "/#{path.path}" if last_uri_host[-1] != '/'
        path.path = "#{last_uri_host}#{path.path}"
      end

      if path.relative? && path.host
        new_uri = options[:uri_adapter].parse("#{@last_uri.scheme}:#{path}").normalize
      elsif path.relative?
        new_uri = options[:uri_adapter].parse("#{base_uri}#{path}").normalize
      else
        new_uri = path.clone
      end

      # avoid double query string on redirects [#12]
      unless redirect
        new_uri.query = query_string(new_uri)
      end

      unless SupportedURISchemes.include? new_uri.scheme
        raise UnsupportedURIScheme, "'#{new_uri}' Must be HTTP, HTTPS or Generic"
      end

      @last_uri = new_uri
    end

    def base_uri
      if redirect
        base_uri = "#{@last_uri.scheme}://#{@last_uri.host}"
        base_uri = "#{base_uri}:#{@last_uri.port}" if @last_uri.port != 80
        base_uri
      else
        options[:base_uri] && HTTParty.normalize_base_uri(options[:base_uri])
      end
    end

    def format
      options[:format] || (format_from_mimetype(last_response['content-type']) if last_response)
    end

    def parser
      options[:parser]
    end

    def connection_adapter
      options[:connection_adapter]
    end

    def perform(&block)
      validate
      setup_raw_request
      chunked_body = nil
      current_http = http

      self.last_response = current_http.request(@raw_request) do |http_response|
        if block
          chunks = []

          http_response.read_body do |fragment|
            encoded_fragment = encode_text(fragment, http_response['content-type'])
            chunks << encoded_fragment if !options[:stream_body]
            block.call ResponseFragment.new(encoded_fragment, http_response, current_http)
          end

          chunked_body = chunks.join
        end
      end

      handle_host_redirection if response_redirects?
      result = handle_unauthorized
      result ||= handle_response(chunked_body, &block)
      result
    end

    def handle_unauthorized(&block)
      return unless digest_auth? && response_unauthorized? && response_has_digest_auth_challenge?
      return if @credentials_sent
      @credentials_sent = true
      perform(&block)
    end

    def raw_body
      @raw_request.body
    end

    def _dump(_level)
      opts = options.dup
      opts.delete(:logger)
      opts.delete(:parser) if opts[:parser] && opts[:parser].is_a?(Proc)
      Marshal.dump([http_method, path, opts, last_response, @last_uri, @raw_request])
    end

    private

    def http
      connection_adapter.call(uri, options)
    end

    def credentials
      (options[:basic_auth] || options[:digest_auth]).to_hash
    end

    def username
      credentials[:username]
    end

    def password
      credentials[:password]
    end

    def normalize_query(query)
      if query_string_normalizer
        query_string_normalizer.call(query)
      else
        HashConversions.to_params(query)
      end
    end

    def query_string_normalizer
      options[:query_string_normalizer]
    end

    def setup_raw_request
      if options[:headers].respond_to?(:to_hash)
        headers_hash = options[:headers].to_hash
      else
        headers_hash = nil
      end

      @raw_request = http_method.new(request_uri(uri), headers_hash)
      @raw_request.body_stream = options[:body_stream] if options[:body_stream]

      if options[:body]
        body = Body.new(
          options[:body],
          query_string_normalizer: query_string_normalizer,
          force_multipart: options[:multipart]
        )

        if body.multipart?
          content_type = "multipart/form-data; boundary=#{body.boundary}"
          @raw_request['Content-Type'] = content_type
        end
        @raw_request.body = body.call
      end

      @raw_request.instance_variable_set(:@decode_content, decompress_content?)

      if options[:basic_auth] && send_authorization_header?
        @raw_request.basic_auth(username, password)
        @credentials_sent = true
      end
      setup_digest_auth if digest_auth? && response_unauthorized? && response_has_digest_auth_challenge?
    end

    def digest_auth?
      !!options[:digest_auth]
    end

    def decompress_content?
      !options[:skip_decompression]
    end

    def response_unauthorized?
      !!last_response && last_response.code == '401'
    end

    def response_has_digest_auth_challenge?
      !last_response['www-authenticate'].nil? && last_response['www-authenticate'].length > 0
    end

    def setup_digest_auth
      @raw_request.digest_auth(username, password, last_response)
    end

    def query_string(uri)
      query_string_parts = []
      query_string_parts << uri.query unless uri.query.nil?

      if options[:query].respond_to?(:to_hash)
        query_string_parts << normalize_query(options[:default_params].merge(options[:query].to_hash))
      else
        query_string_parts << normalize_query(options[:default_params]) unless options[:default_params].empty?
        query_string_parts << options[:query] unless options[:query].nil?
      end

      query_string_parts.reject!(&:empty?) unless query_string_parts == ['']
      query_string_parts.size > 0 ? query_string_parts.join('&') : nil
    end

    def assume_utf16_is_big_endian
      options[:assume_utf16_is_big_endian]
    end

    def handle_response(raw_body, &block)
      if response_redirects?
        options[:limit] -= 1
        if options[:logger]
          logger = HTTParty::Logger.build(options[:logger], options[:log_level], options[:log_format])
          logger.format(self, last_response)
        end
        self.path = last_response['location']
        self.redirect = true
        if last_response.class == Net::HTTPSeeOther
          unless options[:maintain_method_across_redirects] && options[:resend_on_redirect]
            self.http_method = Net::HTTP::Get
          end
        elsif last_response.code != '307' && last_response.code != '308'
          unless options[:maintain_method_across_redirects]
            self.http_method = Net::HTTP::Get
          end
        end
        capture_cookies(last_response)
        perform(&block)
      else
        raw_body ||= last_response.body

        body = decompress(raw_body, last_response['content-encoding']) unless raw_body.nil?

        unless body.nil?
          body = encode_text(body, last_response['content-type'])

          if decompress_content?
            last_response.delete('content-encoding')
            raw_body = body
          end
        end

        Response.new(self, last_response, lambda { parse_response(body) }, body: raw_body)
      end
    end

    def handle_host_redirection
      check_duplicate_location_header
      redirect_path = options[:uri_adapter].parse(last_response['location']).normalize
      return if redirect_path.relative? || path.host == redirect_path.host
      @changed_hosts = true
    end

    def check_duplicate_location_header
      location = last_response.get_fields('location')
      if location.is_a?(Array) && location.count > 1
        raise DuplicateLocationHeader.new(last_response)
      end
    end

    def send_authorization_header?
      !@changed_hosts
    end

    def response_redirects?
      case last_response
      when Net::HTTPNotModified # 304
        false
      when Net::HTTPRedirection
        options[:follow_redirects] && last_response.key?('location')
      end
    end

    def parse_response(body)
      parser.call(body, format)
    end

    def capture_cookies(response)
      return unless response['Set-Cookie']
      cookies_hash = HTTParty::CookieHash.new
      cookies_hash.add_cookies(options[:headers].to_hash['Cookie']) if options[:headers] && options[:headers].to_hash['Cookie']
      response.get_fields('Set-Cookie').each { |cookie| cookies_hash.add_cookies(cookie) }

      options[:headers] ||= {}
      options[:headers]['Cookie'] = cookies_hash.to_cookie_string
    end

    # Uses the HTTP Content-Type header to determine the format of the
    # response It compares the MIME type returned to the types stored in the
    # SupportedFormats hash
    def format_from_mimetype(mimetype)
      if mimetype && parser.respond_to?(:format_from_mimetype)
        parser.format_from_mimetype(mimetype)
      end
    end

    def validate
      raise HTTParty::RedirectionTooDeep.new(last_response), 'HTTP redirects too deep' if options[:limit].to_i <= 0
      raise ArgumentError, 'only get, post, patch, put, delete, head, and options methods are supported' unless SupportedHTTPMethods.include?(http_method)
      raise ArgumentError, ':headers must be a hash' if options[:headers] && !options[:headers].respond_to?(:to_hash)
      raise ArgumentError, 'only one authentication method, :basic_auth or :digest_auth may be used at a time' if options[:basic_auth] && options[:digest_auth]
      raise ArgumentError, ':basic_auth must be a hash' if options[:basic_auth] && !options[:basic_auth].respond_to?(:to_hash)
      raise ArgumentError, ':digest_auth must be a hash' if options[:digest_auth] && !options[:digest_auth].respond_to?(:to_hash)
      raise ArgumentError, ':query must be hash if using HTTP Post' if post? && !options[:query].nil? && !options[:query].respond_to?(:to_hash)
    end

    def post?
      Net::HTTP::Post == http_method
    end

    def set_basic_auth_from_uri
      if path.userinfo
        username, password = path.userinfo.split(':')
        options[:basic_auth] = {username: username, password: password}
        @credentials_sent = true
      end
    end

    def decompress(body, encoding)
      Decompressor.new(body, encoding).decompress
    end

    def encode_text(text, content_type)
      TextEncoder.new(
        text,
        content_type: content_type,
        assume_utf16_is_big_endian: assume_utf16_is_big_endian
      ).call
    end
  end
end
