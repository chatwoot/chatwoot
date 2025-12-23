# frozen_string_literal: true

module HTTP
  class Response
    def to_webmock
      webmock_response = ::WebMock::Response.new

      webmock_response.status  = [status.to_i, reason]

      webmock_response.body    = body.to_s
      # This call is used to reset the body of the response to enable it to be streamed if necessary.
      # The `body.to_s` call above reads the body, which allows WebMock to trigger any registered callbacks.
      # However, once the body is read to_s, it cannot be streamed again and attempting to do so
      # will raise a "HTTP::StateError: body has already been consumed" error.
      # To avoid this error, we replace the original body with a new one.
      # The new body has its @stream attribute set to new Streamer, instead of the original Connection.
      # Unfortunately, it's not possible to reset the original body to its initial streaming state.
      # Therefore, this replacement is the best workaround currently available.
      reset_body_to_allow_it_to_be_streamed!(webmock_response)

      webmock_response.headers = headers.to_h
      webmock_response
    end

    class << self
      def from_webmock(request, webmock_response, request_signature = nil)
        status  = Status.new(webmock_response.status.first)
        headers = webmock_response.headers || {}
        uri     = normalize_uri(request_signature && request_signature.uri)

        # HTTP.rb 3.0+ uses a keyword argument to pass the encoding, but 1.x
        # and 2.x use a positional argument, and 0.x don't support supplying
        # the encoding.
        body = build_http_rb_response_body_from_webmock_response(webmock_response)

        return new(status, "1.1", headers, body, uri) if HTTP::VERSION < "1.0.0"

        # 5.0.0 had a breaking change to require request instead of uri.
        if HTTP::VERSION < '5.0.0'
          return new({
            status: status,
            version: "1.1",
            headers: headers,
            body: body,
            uri: uri
          })
        end

        new({
          status: status,
          version: "1.1",
          headers: headers,
          body: body,
          request: request,
        })
      end

      def build_http_rb_response_body_from_webmock_response(webmock_response)
        if HTTP::VERSION < "1.0.0"
          Body.new(Streamer.new(webmock_response.body))
        elsif HTTP::VERSION < "3.0.0"
          Body.new(Streamer.new(webmock_response.body), webmock_response.body.encoding)
        else
          Body.new(
            Streamer.new(webmock_response.body, encoding: webmock_response.body.encoding),
            encoding: webmock_response.body.encoding
          )
        end
      end

      def normalize_uri(uri)
        return unless uri

        uri = Addressable::URI.parse uri
        uri.port = nil if uri.default_port && uri.port == uri.default_port

        uri
      end
    end

    private

    def reset_body_to_allow_it_to_be_streamed!(webmock_response)
      @body = self.class.build_http_rb_response_body_from_webmock_response(webmock_response)
    end
  end
end
