module Koala

  class KoalaError < StandardError; end

  module Facebook

    # The OAuth signature is incomplete, invalid, or using an unsupported algorithm
    class OAuthSignatureError < ::Koala::KoalaError; end

    # Required for realtime updates validation
    class AppSecretNotDefinedError < ::Koala::KoalaError; end

    # Facebook responded with an error to an API request. If the exception contains a nil
    # http_status, then the error was detected before making a call to Facebook. (e.g. missing access token)
    class APIError < ::Koala::KoalaError
      attr_accessor :http_status,
                    :response_body,
                    :fb_error_type,
                    :fb_error_code,
                    :fb_error_subcode,
                    :fb_error_message,
                    :fb_error_user_msg,
                    :fb_error_user_title,
                    :fb_error_trace_id,
                    :fb_error_debug,
                    :fb_error_rev,
                    :fb_buc_usage,
                    :fb_ada_usage,
                    :fb_app_usage

      # Create a new API Error
      #
      # @param http_status [Integer] The HTTP status code of the response
      # @param response_body [String] The response body
      # @param error_info One of the following:
      #                   [Hash] The error information extracted from the request
      #                          ("type", "code", "error_subcode", "message")
      #                   [String] The error description
      #                   If error_info is nil or not provided, the method will attempt to extract
      #                   the error info from the response_body
      #
      # @return the newly created APIError
      def initialize(http_status, response_body, error_info = nil)
        if response_body
          self.response_body = response_body.strip
        else
          self.response_body = ''
        end
        self.http_status = http_status

        if error_info && error_info.is_a?(String)
          message = error_info
        else
          unless error_info
            begin
              error_info = JSON.parse(response_body)['error'] if response_body
            rescue
            end
            error_info ||= {}
          end

          self.fb_error_type = error_info["type"]
          self.fb_error_code = error_info["code"]
          self.fb_error_subcode = error_info["error_subcode"]
          self.fb_error_message = error_info["message"]
          self.fb_error_user_msg = error_info["error_user_msg"]
          self.fb_error_user_title = error_info["error_user_title"]

          self.fb_error_trace_id = error_info["x-fb-trace-id"]
          self.fb_error_debug = error_info["x-fb-debug"]
          self.fb_error_rev = error_info["x-fb-rev"]
          self.fb_buc_usage = json_parse_for(error_info, "x-business-use-case-usage")
          self.fb_ada_usage = json_parse_for(error_info, "x-ad-account-usage")
          self.fb_app_usage = json_parse_for(error_info, "x-app-usage")

          error_array = []
          %w(type code error_subcode message error_user_title error_user_msg x-fb-trace-id).each do |key|
            error_array << "#{key}: #{error_info[key]}" if error_info[key]
          end

          if error_array.empty?
            message = self.response_body
          else
            message = error_array.join(', ')
          end
        end
        message += " [HTTP #{http_status}]" if http_status

        super(message)
      end

      private

      # refs: https://developers.facebook.com/docs/graph-api/overview/rate-limiting/#headers
      # NOTE: The header will contain a JSON-formatted string that describes current application rate limit usage.
      def json_parse_for(error_info, key)
        string = error_info[key]
        return if string.nil?

        JSON.parse(string)
      rescue JSON::ParserError => e
        Koala::Utils.logger.error("#{e.class}: #{e.message} while parsing #{key} = #{string}")
        nil
      end
    end

    # Facebook returned an invalid response body
    class BadFacebookResponse < APIError; end

    # Facebook responded with an error while attempting to request an access token
    class OAuthTokenRequestError < APIError; end

    # Any error with a 5xx HTTP status code
    class ServerError < APIError; end

    # Any error with a 4xx HTTP status code
    class ClientError < APIError; end

    # All graph API authentication failures.
    class AuthenticationError < ClientError; end

  end

end
