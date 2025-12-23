# frozen_string_literal: true

begin
  require 'curb'
rescue LoadError
  # curb not found
end

if defined?(Curl)
  WebMock::VersionChecker.new('Curb', Curl::CURB_VERSION, '0.7.16', '1.0.1', ['0.8.7']).check_version!

  module WebMock
    module HttpLibAdapters
      class CurbAdapter < HttpLibAdapter
        adapter_for :curb

        OriginalCurlEasy = Curl::Easy unless const_defined?(:OriginalCurlEasy)

        def self.enable!
          Curl.send(:remove_const, :Easy)
          Curl.send(:const_set, :Easy, Curl::WebMockCurlEasy)
        end

        def self.disable!
          Curl.send(:remove_const, :Easy)
          Curl.send(:const_set, :Easy, OriginalCurlEasy)
        end

        # Borrowed from Patron:
        # http://github.com/toland/patron/blob/master/lib/patron/response.rb
        def self.parse_header_string(header_string)
          status, headers = nil, {}

          header_string.split(/\r\n/).each do |header|
            if header =~ %r|^HTTP/1.[01] \d\d\d (.*)|
              status = $1
            else
              parts = header.split(':', 2)
              unless parts.empty?
                parts[1].strip! unless parts[1].nil?
                if headers.has_key?(parts[0])
                  headers[parts[0]] = [headers[parts[0]]] unless headers[parts[0]].kind_of? Array
                  headers[parts[0]] << parts[1]
                else
                  headers[parts[0]] = parts[1]
                end
              end
            end
          end

          return status, headers
        end
      end
    end
  end

  module Curl
    class WebMockCurlEasy < Curl::Easy
      def curb_or_webmock
        request_signature = build_request_signature
        WebMock::RequestRegistry.instance.requested_signatures.put(request_signature)

        if webmock_response = WebMock::StubRegistry.instance.response_for_request(request_signature)
          build_curb_response(webmock_response)
          WebMock::CallbackRegistry.invoke_callbacks(
            {lib: :curb}, request_signature, webmock_response)
          invoke_curb_callbacks
          true
        elsif WebMock.net_connect_allowed?(request_signature.uri)
          res = yield
          if WebMock::CallbackRegistry.any_callbacks?
            webmock_response = build_webmock_response
            WebMock::CallbackRegistry.invoke_callbacks(
              {lib: :curb, real_request: true}, request_signature,
                webmock_response)
          end
          res
        else
          raise WebMock::NetConnectNotAllowedError.new(request_signature)
        end
      end

      def build_request_signature
        method = @webmock_method.to_s.downcase.to_sym

        uri = WebMock::Util::URI.heuristic_parse(self.url)
        uri.path = uri.normalized_path.gsub("[^:]//","/")

        headers = headers_as_hash(self.headers).merge(basic_auth_headers)

        request_body = case method
        when :post, :patch
          self.post_body || @post_body
        when :put
          @put_data
        else
          nil
        end

        if defined?( @on_debug )
          @on_debug.call("Trying 127.0.0.1...\r\n", 0)
          @on_debug.call('Connected to ' + uri.hostname + "\r\n", 0)
          @debug_method = method.upcase
          @debug_path = uri.path
          @debug_host = uri.hostname
          http_request = ["#{@debug_method} #{@debug_path} HTTP/1.1"]
          http_request << "Host: #{uri.hostname}"
          headers.each do |name, value|
            http_request << "#{name}: #{value}"
          end
          @on_debug.call(http_request.join("\r\n") + "\r\n\r\n", 2)
          if request_body
            @on_debug.call(request_body + "\r\n", 4)
            @on_debug.call(
              "upload completely sent off: #{request_body.bytesize}"\
              " out of #{request_body.bytesize} bytes\r\n", 0
            )
          end
        end

        request_signature = WebMock::RequestSignature.new(
          method,
          uri.to_s,
          body: request_body,
          headers: headers
        )
        request_signature
      end

      def headers_as_hash(headers)
        if headers.is_a?(Array)
          headers.inject({}) {|hash, header|
            name, value = header.split(":", 2).map(&:strip)
            hash[name] = value
            hash
          }
        else
          headers
        end
      end

      def basic_auth_headers
        if self.username
          {'Authorization' => WebMock::Util::Headers.basic_auth_header(self.username, self.password)}
        else
          {}
        end
      end

      def build_curb_response(webmock_response)
        raise Curl::Err::TimeoutError if webmock_response.should_timeout
        webmock_response.raise_error_if_any

        @body_str = webmock_response.body
        @response_code = webmock_response.status[0]

        @header_str = "HTTP/1.1 #{webmock_response.status[0]} #{webmock_response.status[1]}\r\n".dup

        @on_debug.call(@header_str, 1) if defined?( @on_debug )

        if webmock_response.headers
          @header_str << webmock_response.headers.map do |k,v|
            header = "#{k}: #{v.is_a?(Array) ? v.join(", ") : v}"
            @on_debug.call(header + "\r\n", 1) if defined?( @on_debug )
            header
          end.join("\r\n")
          @on_debug.call("\r\n", 1) if defined?( @on_debug )

          location = webmock_response.headers['Location']
          if self.follow_location? && location
            @last_effective_url = location
            webmock_follow_location(location)
          end

          @content_type = webmock_response.headers["Content-Type"]
          @transfer_encoding = webmock_response.headers["Transfer-Encoding"]
        end

        @last_effective_url ||= self.url
      end

      def webmock_follow_location(location)
        first_url = self.url
        self.url = location

        curb_or_webmock do
          send( :http, {'method' => @webmock_method} )
        end

        self.url = first_url
      end

      def invoke_curb_callbacks
        @on_progress.call(0.0,1.0,0.0,1.0) if defined?( @on_progress )
        self.header_str.lines.each { |header_line| @on_header.call header_line } if defined?( @on_header )
        if defined?( @on_body )
          if chunked_response?
            self.body_str.each do |chunk|
              @on_body.call(chunk)
            end
          else
            @on_body.call(self.body_str)
          end
        end
        @on_complete.call(self) if defined?( @on_complete )

        case response_code
        when 200..299
          @on_success.call(self) if defined?( @on_success )
        when 400..499
          @on_missing.call(self, self.response_code) if defined?( @on_missing )
        when 500..599
          @on_failure.call(self, self.response_code) if defined?( @on_failure )
        end
      end

      def chunked_response?
        defined?( @transfer_encoding ) && @transfer_encoding == 'chunked' && self.body_str.respond_to?(:each)
      end

      def build_webmock_response
        status, headers =
         WebMock::HttpLibAdapters::CurbAdapter.parse_header_string(self.header_str)

        if defined?( @on_debug )
          http_response = ["HTTP/1.0 #{@debug_method} #{@debug_path}"]
          headers.each do |name, value|
            http_response << "#{name}: #{value}"
          end
          http_response << self.body_str
          @on_debug.call(http_response.join("\r\n") + "\r\n", 3)
          @on_debug.call("Connection #0 to host #{@debug_host} left intact\r\n", 0)
        end

        webmock_response = WebMock::Response.new
        webmock_response.status = [self.response_code, status]
        webmock_response.body = self.body_str
        webmock_response.headers = headers
        webmock_response
      end

      ###
      ### Mocks of Curl::Easy methods below here.
      ###

      def http(method)
        @webmock_method = method
        super
      end

      %w[ get head delete ].each do |verb|
        define_method "http_#{verb}" do
          @webmock_method = verb
          super()
        end
      end

      def http_put data = nil
        @webmock_method = :put
        @put_data = data if data
        super
      end
      alias put http_put

      def http_post *data
        @webmock_method = :post
        @post_body = data.join('&') if data && !data.empty?
        super
      end
      alias post http_post

      def perform
        @webmock_method ||= :get
        curb_or_webmock { super }
      ensure
        reset_webmock_method
      end

      def put_data= data
        @webmock_method = :put
        @put_data = data
        super
      end

      def post_body= data
        @webmock_method = :post
        super
      end

      def delete= value
        @webmock_method = :delete if value
        super
      end

      def head= value
        @webmock_method = :head if value
        super
      end

      def verbose=(verbose)
        @verbose = verbose
      end

      def verbose?
        @verbose ||= false
      end

      def body_str
        @body_str ||= super
      end
      alias body body_str

      def response_code
        @response_code ||= super
      end

      def header_str
        @header_str ||= super
      end
      alias head header_str

      def last_effective_url
        @last_effective_url ||= super
      end

      def content_type
        @content_type ||= super
      end

      %w[ success failure missing header body complete progress debug ].each do |callback|
        class_eval <<-METHOD, __FILE__, __LINE__
          def on_#{callback} &block
            @on_#{callback} = block
            super
          end
        METHOD
      end

      def reset_webmock_method
        @webmock_method = :get
      end

      def reset
        instance_variable_set(:@body_str, nil)
        instance_variable_set(:@content_type, nil)
        instance_variable_set(:@header_str, nil)
        instance_variable_set(:@last_effective_url, nil)
        instance_variable_set(:@response_code, nil)
        super
      end
    end
  end
end
