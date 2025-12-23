# frozen_string_literal: true

require 'net/http'
require 'net/https'
require 'stringio'
require File.join(File.dirname(__FILE__), 'net_http_response')


module WebMock
  module HttpLibAdapters
    class NetHttpAdapter < HttpLibAdapter
      adapter_for :net_http

      OriginalNetHTTP = Net::HTTP unless const_defined?(:OriginalNetHTTP)

      def self.enable!
        Net.send(:remove_const, :HTTP)
        Net.send(:remove_const, :HTTPSession)
        Net.send(:const_set, :HTTP, @webMockNetHTTP)
        Net.send(:const_set, :HTTPSession, @webMockNetHTTP)
      end

      def self.disable!
        Net.send(:remove_const, :HTTP)
        Net.send(:remove_const, :HTTPSession)
        Net.send(:const_set, :HTTP, OriginalNetHTTP)
        Net.send(:const_set, :HTTPSession, OriginalNetHTTP)

        #copy all constants from @webMockNetHTTP to original Net::HTTP
        #in case any constants were added to @webMockNetHTTP instead of Net::HTTP
        #after WebMock was enabled.
        #i.e Net::HTTP::DigestAuth
        @webMockNetHTTP.constants.each do |constant|
          if !OriginalNetHTTP.constants.map(&:to_s).include?(constant.to_s)
            OriginalNetHTTP.send(:const_set, constant, @webMockNetHTTP.const_get(constant))
          end
        end
      end

      @webMockNetHTTP = Class.new(Net::HTTP) do
        class << self
          def socket_type
            StubSocket
          end

          if Module.method(:const_defined?).arity == 1
            def const_defined?(name)
              super || self.superclass.const_defined?(name)
            end
          else
            def const_defined?(name, inherit=true)
              super || self.superclass.const_defined?(name, inherit)
            end
          end

          if Module.method(:const_get).arity != 1
            def const_get(name, inherit=true)
              super
            rescue NameError
              self.superclass.const_get(name, inherit)
            end
          end

          if Module.method(:constants).arity != 0
            def constants(inherit=true)
              (super + self.superclass.constants(inherit)).uniq
            end
          end
        end

        def request(request, body = nil, &block)
          request_signature = WebMock::NetHTTPUtility.request_signature_from_request(self, request, body)

          WebMock::RequestRegistry.instance.requested_signatures.put(request_signature)

          if webmock_response = WebMock::StubRegistry.instance.response_for_request(request_signature)
            @socket = Net::HTTP.socket_type.new
            WebMock::CallbackRegistry.invoke_callbacks(
              {lib: :net_http}, request_signature, webmock_response)
            build_net_http_response(webmock_response, request.uri, &block)
          elsif WebMock.net_connect_allowed?(request_signature.uri)
            check_right_http_connection
            after_request = lambda do |response|
              if WebMock::CallbackRegistry.any_callbacks?
                webmock_response = build_webmock_response(response)
                WebMock::CallbackRegistry.invoke_callbacks(
                  {lib: :net_http, real_request: true}, request_signature, webmock_response)
              end
              response.extend Net::WebMockHTTPResponse
              block.call response if block
              response
            end
            super_with_after_request = lambda {
              response = super(request, nil, &nil)
              after_request.call(response)
            }
            if started?
              ensure_actual_connection
              super_with_after_request.call
            else
              start_with_connect {
                super_with_after_request.call
              }
            end
          else
            raise WebMock::NetConnectNotAllowedError.new(request_signature)
          end
        end

        def start_without_connect
          raise IOError, 'HTTP session already opened' if @started
          if block_given?
            begin
              @socket = Net::HTTP.socket_type.new
              @started = true
              return yield(self)
            ensure
              do_finish
            end
          end
          @socket = Net::HTTP.socket_type.new
          @started = true
          self
        end


        def ensure_actual_connection
          if @socket.is_a?(StubSocket)
            @socket&.close
            @socket = nil
            do_start
          end
        end

        alias_method :start_with_connect, :start

        def start(&block)
          uri = Addressable::URI.parse(WebMock::NetHTTPUtility.get_uri(self))

          if WebMock.net_http_connect_on_start?(uri)
            super(&block)
          else
            start_without_connect(&block)
          end
        end

        def build_net_http_response(webmock_response, request_uri, &block)
          response = Net::HTTPResponse.send(:response_class, webmock_response.status[0].to_s).new("1.0", webmock_response.status[0].to_s, webmock_response.status[1])
          body = webmock_response.body
          body = nil if webmock_response.status[0].to_s == '204'

          response.instance_variable_set(:@body, body)
          webmock_response.headers.to_a.each do |name, values|
            values = [values] unless values.is_a?(Array)
            values.each do |value|
              response.add_field(name, value)
            end
          end

          response.instance_variable_set(:@read, true)

          response.uri = request_uri

          response.extend Net::WebMockHTTPResponse

          if webmock_response.should_timeout
            raise Net::OpenTimeout, "execution expired"
          end

          webmock_response.raise_error_if_any

          yield response if block_given?

          response
        end

        def build_webmock_response(net_http_response)
          webmock_response = WebMock::Response.new
          webmock_response.status = [
             net_http_response.code.to_i,
             net_http_response.message]
          webmock_response.headers = net_http_response.to_hash
          webmock_response.body = net_http_response.body
          webmock_response
        end


        def check_right_http_connection
          unless @@alredy_checked_for_right_http_connection ||= false
            WebMock::NetHTTPUtility.puts_warning_for_right_http_if_needed
            @@alredy_checked_for_right_http_connection = true
          end
        end
      end
      @webMockNetHTTP.version_1_2
      [
        [:Get, Net::HTTP::Get],
        [:Post, Net::HTTP::Post],
        [:Put, Net::HTTP::Put],
        [:Delete, Net::HTTP::Delete],
        [:Head, Net::HTTP::Head],
        [:Options, Net::HTTP::Options]
      ].each do |c|
        @webMockNetHTTP.const_set(c[0], c[1])
      end
    end
  end
end

class StubSocket #:nodoc:

  attr_accessor :read_timeout, :continue_timeout, :write_timeout

  def initialize(*args)
    @closed = false
  end

  def closed?
    @closed
  end

  def close
    @closed = true
    nil
  end

  def readuntil(*args)
  end

  def io
    @io ||= StubIO.new
  end

  class StubIO
    def setsockopt(*args); end
    def peer_cert; end
    def peeraddr; ["AF_INET", 443, "127.0.0.1", "127.0.0.1"] end
    def ssl_version; "TLSv1.3" end
    def cipher; ["TLS_AES_128_GCM_SHA256", "TLSv1.3", 128, 128] end
  end
end

module WebMock
  module NetHTTPUtility

    def self.request_signature_from_request(net_http, request, body = nil)
      path = request.path

      if path.respond_to?(:request_uri) #https://github.com/bblimke/webmock/issues/288
        path = path.request_uri
      end

      path = WebMock::Util::URI.heuristic_parse(path).request_uri if path =~ /^http/

      uri = get_uri(net_http, path)
      method = request.method.downcase.to_sym

      headers = Hash[*request.to_hash.map {|k,v| [k, v]}.inject([]) {|r,x| r + x}]

      if request.body_stream
        body = request.body_stream.read
        request.body_stream = nil
      end

      if body != nil && body.respond_to?(:read)
        request.set_body_internal body.read
      else
        request.set_body_internal body
      end

      WebMock::RequestSignature.new(method, uri, body: request.body, headers: headers)
    end

    def self.get_uri(net_http, path = nil)
      protocol = net_http.use_ssl? ? "https" : "http"

      hostname = net_http.address
      hostname = "[#{hostname}]" if /\A\[.*\]\z/ !~ hostname && /:/ =~ hostname

      "#{protocol}://#{hostname}:#{net_http.port}#{path}"
    end

    def self.check_right_http_connection
      @was_right_http_connection_loaded = defined?(RightHttpConnection)
    end

    def self.puts_warning_for_right_http_if_needed
      if !@was_right_http_connection_loaded && defined?(RightHttpConnection)
        $stderr.puts "\nWarning: RightHttpConnection has to be required before WebMock is required !!!\n"
      end
    end

  end
end

WebMock::NetHTTPUtility.check_right_http_connection
