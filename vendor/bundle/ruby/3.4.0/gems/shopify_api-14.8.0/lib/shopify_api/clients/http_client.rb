# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Clients
    class HttpClient
      extend T::Sig

      RETRY_WAIT_TIME = 1

      sig { params(base_path: String, session: T.nilable(Auth::Session)).void }
      def initialize(base_path:, session: nil)
        session ||= Context.active_session
        raise Errors::NoActiveSessionError, "No passed or active session" unless session

        api_host = Context.api_host

        @base_uri = T.let("https://#{api_host || session.shop}", String)
        @base_uri_and_path = T.let("#{@base_uri}#{base_path}", String)

        user_agent_prefix = Context.user_agent_prefix.nil? ? "" : "#{Context.user_agent_prefix} | "

        @headers = T.let({
          "User-Agent": "#{user_agent_prefix}Shopify API Library v#{VERSION} | Ruby #{RUBY_VERSION}",
          "Accept": "application/json",
        }, T::Hash[T.any(Symbol, String), T.untyped])

        @headers["Host"] = session.shop unless api_host.nil?

        unless session.access_token.nil? || T.must(session.access_token).empty?
          @headers["X-Shopify-Access-Token"] = T.cast(session.access_token, String)
        end
      end

      sig { params(request: HttpRequest, response_as_struct: T::Boolean).returns(HttpResponse) }
      def request(request, response_as_struct: false)
        request.verify

        headers = @headers
        headers["Content-Type"] = T.must(request.body_type) if request.body_type
        headers = headers.merge(T.must(request.extra_headers)) if request.extra_headers

        tries = 0
        response = HttpResponse.new(code: 0, headers: {}, body: "")
        while tries < request.tries
          tries += 1
          res = T.cast(HTTParty.send(
            request.http_method,
            request_url(request),
            headers: headers,
            query: request.query,
            body: request.body.class == Hash ? T.unsafe(request.body).to_json : request.body,
          ), HTTParty::Response)

          begin
            body = res.body.nil? || res.body.empty? ? {} : JSON.parse(res.body)
          rescue JSON::ParserError
            raise if res.code.to_i < 500

            body = res.body
          end

          if response_as_struct && body.is_a?(Hash)
            json_body = body.to_json
            body = JSON.parse(json_body, object_class: OpenStruct)
          end

          response = HttpResponse.new(code: res.code.to_i, headers: res.headers.to_h, body: body)

          if response.headers["x-shopify-api-deprecated-reason"]
            reason = T.must(response.headers["x-shopify-api-deprecated-reason"])[0]
            Context.logger.warn("Deprecated request to Shopify API at #{request.path}, received reason: #{reason}")
          end

          break if response.ok?

          error_message = serialized_error(response)

          unless [429, 500].include?(response.code)
            raise ShopifyAPI::Errors::HttpResponseError.new(response: response), error_message
          end

          if tries == request.tries
            raise ShopifyAPI::Errors::HttpResponseError.new(response: response), error_message if request.tries == 1

            raise ShopifyAPI::Errors::MaxHttpRetriesExceededError.new(response: response),
              "Exceeded maximum retry count of #{request.tries}. Last message: #{error_message}"
          end

          if response.code == 500 || response.headers["retry-after"].nil?
            sleep(RETRY_WAIT_TIME)
          else
            sleep(T.must(response.headers["retry-after"])[0].to_i)
          end
        end

        response
      end

      protected

      sig { params(request: HttpRequest).returns(String) }
      def request_url(request)
        "#{@base_uri_and_path}/#{request.path}"
      end

      sig { params(response: HttpResponse).returns(String) }
      def serialized_error(response)
        body = {}
        body["errors"] = response.body["errors"] if response.body["errors"]

        if response.headers["x-request-id"]
          id = T.must(response.headers["x-request-id"])[0]
          body["error_reference"] = "If you report this error, please include this id: #{id}."
        end
        body.to_json
      end
    end
  end
end
