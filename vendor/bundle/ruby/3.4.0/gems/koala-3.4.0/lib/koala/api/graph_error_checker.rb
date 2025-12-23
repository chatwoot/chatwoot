module Koala
  module Facebook
    # This class, given a Koala::HTTPService::Response object, will check for Graph API-specific
    # errors. This returns an error of the appropriate type which can be immediately raised
    # (non-batch) or added to the list of batch results (batch)
    class GraphErrorChecker
      attr_reader :http_status, :body, :headers
      def initialize(http_status, body, headers)
        @http_status = http_status.to_i
        @body = body
        @headers = headers
      end

      # Facebook has a set of standardized error codes, some of which represent problems with the
      # token.
      AUTHENTICATION_ERROR_CODES = [102, 190, 450, 452, 2500]

      # Facebook can return debug information in the response headers -- see
      # https://developers.facebook.com/docs/graph-api/using-graph-api#bugdebug
      DEBUG_HEADERS = %w[x-fb-debug x-fb-rev x-fb-trace-id x-business-use-case-usage x-ad-account-usage x-app-usage]

      def error_if_appropriate
        if http_status >= 400
          error_class.new(http_status, body, error_info)
        end
      end

      protected

      def error_class
        if auth_error?
          # See: https://developers.facebook.com/docs/authentication/access-token-expiration/
          #      https://developers.facebook.com/bugs/319643234746794?browse=search_4fa075c0bd9117b20604672
          AuthenticationError
        else
          ClientError
        end
      end

      def auth_error?
        # tbh, I'm not sure why we restrict Facebook-reported OAuthExceptions to only those without
        # codes or whose codes match the list above -- let's investigate changing this later.
        error_info['type'] == 'OAuthException' &&
          (!error_info['code'] || AUTHENTICATION_ERROR_CODES.include?(error_info['code'].to_i))
      end

      def error_info
        # Build up the complete error info from whatever Facebook gives us plus the header
        # information
        @error_info ||= DEBUG_HEADERS.inject(base_error_info) do |hash, error_key|
          hash[error_key] = headers[error_key] if headers[error_key]
          hash
        end
      end

      def base_error_info
        response_hash['error'] || {}
      end

      def response_hash
        # Normally, we start with the response body. If it isn't valid JSON, we start with an empty
        # hash and fill it with error data.
        @response_hash ||= begin
          JSON.parse(body)
        rescue JSON::ParserError
          {}
        end
      end
    end
  end
end
