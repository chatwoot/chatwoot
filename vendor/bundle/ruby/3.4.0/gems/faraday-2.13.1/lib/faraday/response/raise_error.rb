# frozen_string_literal: true

module Faraday
  class Response
    # RaiseError is a Faraday middleware that raises exceptions on common HTTP
    # client or server error responses.
    class RaiseError < Middleware
      # rubocop:disable Naming/ConstantName
      ClientErrorStatuses = (400...500)
      ServerErrorStatuses = (500...600)
      ClientErrorStatusesWithCustomExceptions = {
        400 => Faraday::BadRequestError,
        401 => Faraday::UnauthorizedError,
        403 => Faraday::ForbiddenError,
        404 => Faraday::ResourceNotFound,
        408 => Faraday::RequestTimeoutError,
        409 => Faraday::ConflictError,
        422 => Faraday::UnprocessableEntityError,
        429 => Faraday::TooManyRequestsError
      }.freeze
      # rubocop:enable Naming/ConstantName

      DEFAULT_OPTIONS = { include_request: true, allowed_statuses: [] }.freeze

      def on_complete(env)
        return if Array(options[:allowed_statuses]).include?(env[:status])

        case env[:status]
        when *ClientErrorStatusesWithCustomExceptions.keys
          raise ClientErrorStatusesWithCustomExceptions[env[:status]], response_values(env)
        when 407
          # mimic the behavior that we get with proxy requests with HTTPS
          msg = %(407 "Proxy Authentication Required")
          raise Faraday::ProxyAuthError.new(msg, response_values(env))
        when ClientErrorStatuses
          raise Faraday::ClientError, response_values(env)
        when ServerErrorStatuses
          raise Faraday::ServerError, response_values(env)
        when nil
          raise Faraday::NilStatusError, response_values(env)
        end
      end

      # Returns a hash of response data with the following keys:
      #   - status
      #   - headers
      #   - body
      #   - request
      #
      # The `request` key is omitted when the middleware is explicitly
      # configured with the option `include_request: false`.
      def response_values(env)
        response = {
          status: env.status,
          headers: env.response_headers,
          body: env.body
        }

        # Include the request data by default. If the middleware was explicitly
        # configured to _not_ include request data, then omit it.
        return response unless options[:include_request]

        response.merge(
          request: {
            method: env.method,
            url: env.url,
            url_path: env.url.path,
            params: query_params(env),
            headers: env.request_headers,
            body: env.request_body
          }
        )
      end

      def query_params(env)
        env.request.params_encoder ||= Faraday::Utils.default_params_encoder
        env.params_encoder.decode(env.url.query)
      end
    end
  end
end

Faraday::Response.register_middleware(raise_error: Faraday::Response::RaiseError)
