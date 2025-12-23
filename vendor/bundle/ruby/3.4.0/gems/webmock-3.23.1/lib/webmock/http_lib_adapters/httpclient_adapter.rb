# frozen_string_literal: true

begin
  require 'httpclient'
  require 'jsonclient' # defined in 'httpclient' gem as well
rescue LoadError
  # httpclient not found
  # or jsonclient not defined (in old versions of httclient gem)
end

if defined?(::HTTPClient)

  module WebMock
    module HttpLibAdapters
      class HTTPClientAdapter < HttpLibAdapter
        adapter_for :httpclient

        unless const_defined?(:OriginalHttpClient)
          OriginalHttpClient = ::HTTPClient
        end

        unless const_defined?(:OriginalJsonClient)
          OriginalJsonClient = ::JSONClient if defined?(::JSONClient)
        end

        def self.enable!
          Object.send(:remove_const, :HTTPClient)
          Object.send(:const_set, :HTTPClient, WebMockHTTPClient)
          if defined? ::JSONClient
            Object.send(:remove_const, :JSONClient)
            Object.send(:const_set, :JSONClient, WebMockJSONClient)
          end
        end

        def self.disable!
          Object.send(:remove_const, :HTTPClient)
          Object.send(:const_set, :HTTPClient, OriginalHttpClient)
          if defined? ::JSONClient
            Object.send(:remove_const, :JSONClient)
            Object.send(:const_set, :JSONClient, OriginalJsonClient)
          end
        end
      end
    end
  end

  module WebMockHTTPClients
    WEBMOCK_HTTPCLIENT_RESPONSES = :webmock_httpclient_responses
    WEBMOCK_HTTPCLIENT_REQUEST_SIGNATURES = :webmock_httpclient_request_signatures

    REQUEST_RESPONSE_LOCK = Mutex.new

    def do_get_block(req, proxy, conn, &block)
      do_get(req, proxy, conn, false, &block)
    end

    def do_get_stream(req, proxy, conn, &block)
      do_get(req, proxy, conn, true, &block)
    end

    def do_get(req, proxy, conn, stream = false, &block)
      clear_thread_variables unless conn.async_thread

      request_signature = build_request_signature(req, :reuse_existing)

      WebMock::RequestRegistry.instance.requested_signatures.put(request_signature)

      if webmock_responses[request_signature]
        webmock_response = webmock_responses.delete(request_signature)
        response = build_httpclient_response(webmock_response, stream, req.header, &block)
        @request_filter.each do |filter|
          filter.filter_response(req, response)
        end
        res = conn.push(response)
        WebMock::CallbackRegistry.invoke_callbacks(
          {lib: :httpclient}, request_signature, webmock_response)
        res
      elsif WebMock.net_connect_allowed?(request_signature.uri)
        # in case there is a nil entry in the hash...
        webmock_responses.delete(request_signature)

        res = if stream
          do_get_stream_without_webmock(req, proxy, conn, &block)
        elsif block
          body = ''
          do_get_block_without_webmock(req, proxy, conn) do |http_res, chunk|
            if chunk && chunk.bytesize > 0
              body += chunk
              block.call(http_res, chunk)
            end
          end
        else
          do_get_block_without_webmock(req, proxy, conn)
        end
        res = conn.pop
        conn.push(res)
        if WebMock::CallbackRegistry.any_callbacks?
          webmock_response = build_webmock_response(res, body)
          WebMock::CallbackRegistry.invoke_callbacks(
            {lib: :httpclient, real_request: true}, request_signature,
            webmock_response)
        end
        res
      else
        raise WebMock::NetConnectNotAllowedError.new(request_signature)
      end
    end

    def do_request_async(method, uri, query, body, extheader)
      clear_thread_variables
      req = create_request(method, uri, query, body, extheader)
      request_signature = build_request_signature(req)
      webmock_request_signatures << request_signature

      if webmock_responses[request_signature] || WebMock.net_connect_allowed?(request_signature.uri)
        conn = super
        conn.async_thread[WEBMOCK_HTTPCLIENT_REQUEST_SIGNATURES] = Thread.current[WEBMOCK_HTTPCLIENT_REQUEST_SIGNATURES]
        conn.async_thread[WEBMOCK_HTTPCLIENT_RESPONSES] = Thread.current[WEBMOCK_HTTPCLIENT_RESPONSES]
        conn
      else
        raise WebMock::NetConnectNotAllowedError.new(request_signature)
      end
    end

    def build_httpclient_response(webmock_response, stream = false, req_header = nil, &block)
      body = stream ? StringIO.new(webmock_response.body) : webmock_response.body
      response = HTTP::Message.new_response(body, req_header)
      response.header.init_response(webmock_response.status[0])
      response.reason=webmock_response.status[1]
      webmock_response.headers.to_a.each { |name, value| response.header.set(name, value) }

      raise HTTPClient::TimeoutError if webmock_response.should_timeout
      webmock_response.raise_error_if_any

      block.call(response, body) if block && body && body.bytesize > 0

      response
    end

    def build_webmock_response(httpclient_response, body = nil)
      webmock_response = WebMock::Response.new
      webmock_response.status = [httpclient_response.status, httpclient_response.reason]

      webmock_response.headers = {}.tap do |hash|
        httpclient_response.header.all.each do |(key, value)|
          if hash.has_key?(key)
            hash[key] = Array(hash[key]) + [value]
          else
            hash[key] = value
          end
        end
      end

      if body
        webmock_response.body = body
      elsif httpclient_response.content.respond_to?(:read)
        webmock_response.body = httpclient_response.content.read
        body = HTTP::Message::Body.new
        body.init_response(StringIO.new(webmock_response.body))
        httpclient_response.body = body
      else
        webmock_response.body = httpclient_response.content
      end
      webmock_response
    end

    def build_request_signature(req, reuse_existing = false)
      @request_filter.each do |filter|
        filter.filter_request(req)
      end

      uri = WebMock::Util::URI.heuristic_parse(req.header.request_uri.to_s)
      uri.query = WebMock::Util::QueryMapper.values_to_query(req.header.request_query, notation: WebMock::Config.instance.query_values_notation) if req.header.request_query
      uri.port = req.header.request_uri.port

      headers = req.header.all.inject({}) do |hdrs, header|
        hdrs[header[0]] ||= []
        hdrs[header[0]] << header[1]
        hdrs
      end
      headers = headers_from_session(uri).merge(headers)

      signature = WebMock::RequestSignature.new(
        req.header.request_method.downcase.to_sym,
        uri.to_s,
        body: req.http_body.dump,
        headers: headers
      )

      # reuse a previous identical signature object if we stored one for later use
      if reuse_existing && previous_signature = previous_signature_for(signature)
        return previous_signature
      end

      signature
    end

    def webmock_responses
      Thread.current[WEBMOCK_HTTPCLIENT_RESPONSES] ||= Hash.new do |hash, request_signature|
        hash[request_signature] = WebMock::StubRegistry.instance.response_for_request(request_signature)
      end
    end

    def webmock_request_signatures
      Thread.current[WEBMOCK_HTTPCLIENT_REQUEST_SIGNATURES] ||= []
    end

    def previous_signature_for(signature)
      return nil unless index = webmock_request_signatures.index(signature)
      webmock_request_signatures.delete_at(index)
    end

    private

    # some of the headers sent by HTTPClient are derived from
    # the client session
    def headers_from_session(uri)
      session_headers = HTTP::Message::Headers.new
      @session_manager.send(:open, uri).send(:set_header, MessageMock.new(session_headers))
      session_headers.all.inject({}) do |hdrs, header|
        hdrs[header[0]] = header[1]
        hdrs
      end
    end

    def clear_thread_variables
      Thread.current[WEBMOCK_HTTPCLIENT_REQUEST_SIGNATURES] = nil
      Thread.current[WEBMOCK_HTTPCLIENT_RESPONSES] = nil
    end
  end

  class WebMockHTTPClient < HTTPClient
    alias_method :do_get_block_without_webmock, :do_get_block
    alias_method :do_get_stream_without_webmock, :do_get_stream

    include WebMockHTTPClients
  end

  if defined? ::JSONClient
    class WebMockJSONClient < JSONClient
      alias_method :do_get_block_without_webmock, :do_get_block
      alias_method :do_get_stream_without_webmock, :do_get_stream

      include WebMockHTTPClients
    end
  end


  # Mocks a HTTPClient HTTP::Message
  class MessageMock
    attr_reader :header

    def initialize(headers)
      @header = headers
    end

    def http_version=(value);end
  end

end
