# frozen_string_literal: true

module HTTP
  class WebMockPerform
    def initialize(request, options, &perform)
      @request = request
      @options = options
      @perform = perform
      @request_signature = nil
    end

    def exec
      replay || perform || halt
    end

    def request_signature
      unless @request_signature
        @request_signature = @request.webmock_signature
        register_request(@request_signature)
      end

      @request_signature
    end

    protected

    def response_for_request(signature)
      ::WebMock::StubRegistry.instance.response_for_request(signature)
    end

    def register_request(signature)
      ::WebMock::RequestRegistry.instance.requested_signatures.put(signature)
    end

    def replay
      webmock_response = response_for_request request_signature

      return unless webmock_response

      raise_timeout_error if webmock_response.should_timeout
      webmock_response.raise_error_if_any

      invoke_callbacks(webmock_response, real_request: false)
      response = ::HTTP::Response.from_webmock @request, webmock_response, request_signature

      @options.features.each { |_name, feature| response = feature.wrap_response(response) }
      response
    end

    def raise_timeout_error
      raise Errno::ETIMEDOUT if HTTP::VERSION < "1.0.0"
      raise HTTP::TimeoutError, "connection error: #{Errno::ETIMEDOUT.new}"
    end

    def perform
      return unless ::WebMock.net_connect_allowed?(request_signature.uri)
      response = @perform.call
      invoke_callbacks(response.to_webmock, real_request: true)
      response
    end

    def halt
      raise ::WebMock::NetConnectNotAllowedError.new request_signature
    end

    def invoke_callbacks(webmock_response, options = {})
      ::WebMock::CallbackRegistry.invoke_callbacks(
        options.merge({ lib: :http_rb }),
        request_signature,
        webmock_response
      )
    end
  end
end
