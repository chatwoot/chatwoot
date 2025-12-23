# frozen_string_literal: true

begin
  require 'em-http-request'
rescue LoadError
  # em-http-request not found
end

if defined?(EventMachine::HttpClient)
  module WebMock
    module HttpLibAdapters
      class EmHttpRequestAdapter < HttpLibAdapter
        adapter_for :em_http_request

        OriginalHttpClient = EventMachine::HttpClient unless const_defined?(:OriginalHttpClient)
        OriginalHttpConnection = EventMachine::HttpConnection unless const_defined?(:OriginalHttpConnection)

        def self.enable!
          EventMachine.send(:remove_const, :HttpConnection)
          EventMachine.send(:const_set, :HttpConnection, EventMachine::WebMockHttpConnection)
          EventMachine.send(:remove_const, :HttpClient)
          EventMachine.send(:const_set, :HttpClient, EventMachine::WebMockHttpClient)
        end

        def self.disable!
          EventMachine.send(:remove_const, :HttpConnection)
          EventMachine.send(:const_set, :HttpConnection, OriginalHttpConnection)
          EventMachine.send(:remove_const, :HttpClient)
          EventMachine.send(:const_set, :HttpClient, OriginalHttpClient)
        end
      end
    end
  end

  module EventMachine
    if defined?(Synchrony) && HTTPMethods.instance_methods.include?(:aget)
      # have to make the callbacks fire on the next tick in order
      # to avoid the dreaded "double resume" exception
      module HTTPMethods
        %w[get head post delete put].each do |type|
          class_eval %[
            def #{type}(options = {}, &blk)
              f = Fiber.current

               conn = setup_request(:#{type}, options, &blk)
               conn.callback { EM.next_tick { f.resume(conn) } }
               conn.errback  { EM.next_tick { f.resume(conn) } }

               Fiber.yield
            end
          ]
        end
      end
    end

    class WebMockHttpConnection < HttpConnection
      def activate_connection(client)
        request_signature = client.request_signature

        if client.stubbed_webmock_response
          conn = HttpStubConnection.new rand(10000)
          post_init

          @deferred = false
          @conn = conn

          conn.parent = self
          conn.pending_connect_timeout = @connopts.connect_timeout
          conn.comm_inactivity_timeout = @connopts.inactivity_timeout

          finalize_request(client)
          @conn.set_deferred_status :succeeded
        elsif WebMock.net_connect_allowed?(request_signature.uri)
          super
        else
          raise WebMock::NetConnectNotAllowedError.new(request_signature)
        end
      end

      def drop_client
        @clients.shift
      end
    end

    class WebMockHttpClient < EventMachine::HttpClient
      include HttpEncoding

      def uri
        @req.uri
      end

      def setup(response, uri, error = nil)
        @last_effective_url = @uri = uri
        if error
          on_error(error)
          @conn.drop_client
          fail(self)
        else
          @conn.receive_data(response)
          succeed(self)
        end
      end

      def connection_completed
        @state = :response_header
        send_request(*headers_and_body_processed_by_middleware)
      end

      def send_request(head, body)
        WebMock::RequestRegistry.instance.requested_signatures.put(request_signature)

        if stubbed_webmock_response
          WebMock::CallbackRegistry.invoke_callbacks({lib: :em_http_request}, request_signature, stubbed_webmock_response)
          @uri ||= nil
          EM.next_tick {
            setup(make_raw_response(stubbed_webmock_response), @uri,
                  stubbed_webmock_response.should_timeout ? Errno::ETIMEDOUT : nil)
          }
          self
        elsif WebMock.net_connect_allowed?(request_signature.uri)
          super
        else
          raise WebMock::NetConnectNotAllowedError.new(request_signature)
        end
      end

      def unbind(reason = nil)
        if !stubbed_webmock_response && WebMock::CallbackRegistry.any_callbacks?
          webmock_response = build_webmock_response
          WebMock::CallbackRegistry.invoke_callbacks(
            {lib: :em_http_request, real_request: true},
            request_signature,
            webmock_response)
        end
        @request_signature = nil
        remove_instance_variable(:@stubbed_webmock_response)

        super
      end

      def request_signature
        @request_signature ||= build_request_signature
      end

      def stubbed_webmock_response
        unless defined?(@stubbed_webmock_response)
          @stubbed_webmock_response = WebMock::StubRegistry.instance.response_for_request(request_signature)
        end

        @stubbed_webmock_response
      end

      def get_response_cookie(name)
        name = name.to_s

        raw_cookie = response_header.cookie
        raw_cookie = [raw_cookie] if raw_cookie.is_a? String

        cookie = raw_cookie.detect { |c| c.start_with? name }
        cookie and cookie.split('=', 2)[1]
      end

      private

      def build_webmock_response
        webmock_response = WebMock::Response.new
        webmock_response.status = [response_header.status, response_header.http_reason]
        webmock_response.headers = response_header
        webmock_response.body = response
        webmock_response
      end

      def headers_and_body_processed_by_middleware
        @headers_and_body_processed_by_middleware ||= begin
          head, body = build_request, @req.body
          @conn.middleware.each do |m|
            head, body = m.request(self, head, body) if m.respond_to?(:request)
          end
          [head, body]
        end
      end

      def build_request_signature
        headers, body = headers_and_body_processed_by_middleware

        method = @req.method
        uri = @req.uri.clone
        query = @req.query

        uri.query = encode_query(@req.uri, query).slice(/\?(.*)/, 1)

        body = form_encode_body(body) if body.is_a?(Hash)

        if headers['authorization'] && headers['authorization'].is_a?(Array)
          headers['Authorization'] = WebMock::Util::Headers.basic_auth_header(headers.delete('authorization'))
        end

        WebMock::RequestSignature.new(
          method.downcase.to_sym,
          uri.to_s,
          body: body || (@req.file && File.read(@req.file)),
          headers: headers
        )
      end

      def make_raw_response(response)
        response.raise_error_if_any

        status, headers, body = response.status, response.headers, response.body
        headers ||= {}

        response_string = []
        response_string << "HTTP/1.1 #{status[0]} #{status[1]}"

        headers["Content-Length"] = body.bytesize unless headers["Content-Length"]
        headers.each do |header, value|
          if header =~ /set-cookie/i
            [value].flatten.each do |cookie|
              response_string << "#{header}: #{cookie}"
            end
          else
            value = value.join(", ") if value.is_a?(Array)

            # WebMock's internal processing will not handle the body
            # correctly if the header indicates that it is chunked, unless
            # we also create all the chunks.
            # It's far easier just to remove the header.
            next if header =~ /transfer-encoding/i && value =~/chunked/i

            response_string << "#{header}: #{value}"
          end
        end if headers

        response_string << "" << body
        response_string.join("\n")
      end
    end
  end
end
