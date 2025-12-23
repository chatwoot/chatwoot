# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "googleauth"
require "gapic/rest/faraday_middleware"
require "faraday/retry"

module Gapic
  module Rest
    ##
    # A class for making REST calls through Faraday
    # ClientStub's responsibilities:
    #   - wrap Faraday methods with a bounded explicit interface
    #   - store service endpoint and create full url for the request
    #   - store credentials and add auth information to the request
    #
    class ClientStub
      ##
      # Initializes with an endpoint and credentials
      # @param endpoint [String] an endpoint for the service that this stub will send requests to
      # @param credentials [Google::Auth::Credentials]
      #   Credentials to send with calls in form of a googleauth credentials object.
      #   (see the [googleauth docs](https://googleapis.dev/ruby/googleauth/latest/index.html))
      # @param numeric_enums [Boolean] Whether to signal the server to JSON-encode enums as ints
      #
      # @param raise_faraday_errors [Boolean]
      #   Whether to raise Faraday errors instead of wrapping them in `Gapic::Rest::Error`
      #   Added for backwards compatibility.
      #   Default is `true`. All REST clients (except for old versions of `google-cloud-compute-v1`)
      #   should explicitly set this parameter to `false`.
      #
      # @yield [Faraday::Connection]
      #
      def initialize endpoint:, credentials:, numeric_enums: false, raise_faraday_errors: true
        @endpoint = endpoint
        @endpoint = "https://#{endpoint}" unless /^https?:/.match? endpoint
        @endpoint = @endpoint.sub %r{/$}, ""

        @credentials = credentials
        @numeric_enums = numeric_enums

        @raise_faraday_errors = raise_faraday_errors

        @connection = Faraday.new url: @endpoint do |conn|
          conn.headers = { "Content-Type" => "application/json" }
          conn.request :google_authorization, @credentials unless @credentials.is_a? ::Symbol
          conn.request :retry
          conn.response :raise_error
          conn.adapter :net_http
        end

        yield @connection if block_given?
      end

      ##
      # Makes a GET request
      #
      # @param uri [String] uri to send this request to
      # @param params [Hash] query string parameters for the request
      # @param options [::Gapic::CallOptions,Hash] gapic options to be applied
      #     to the REST call. Currently only timeout and headers are supported.
      # @return [Faraday::Response]
      def make_get_request uri:, params: {}, options: {}
        make_http_request :get, uri: uri, body: nil, params: params, options: options
      end

      ##
      # Makes a DELETE request
      #
      # @param uri [String] uri to send this request to
      # @param params [Hash] query string parameters for the request
      # @param options [::Gapic::CallOptions,Hash] gapic options to be applied
      #     to the REST call. Currently only timeout and headers are supported.
      # @return [Faraday::Response]
      def make_delete_request uri:, params: {}, options: {}
        make_http_request :delete, uri: uri, body: nil, params: params, options: options
      end

      ##
      # Makes a PATCH request
      #
      # @param uri [String] uri to send this request to
      # @param body [String] a body to send with the request, nil for requests without a body
      # @param params [Hash] query string parameters for the request
      # @param options [::Gapic::CallOptions,Hash] gapic options to be applied
      #     to the REST call. Currently only timeout and headers are supported.
      # @return [Faraday::Response]
      def make_patch_request uri:, body:, params: {}, options: {}
        make_http_request :patch, uri: uri, body: body, params: params, options: options
      end

      ##
      # Makes a POST request
      #
      # @param uri [String] uri to send this request to
      # @param body [String] a body to send with the request, nil for requests without a body
      # @param params [Hash] query string parameters for the request
      # @param options [::Gapic::CallOptions,Hash] gapic options to be applied
      #     to the REST call. Currently only timeout and headers are supported.
      # @return [Faraday::Response]
      def make_post_request uri:, body: nil, params: {}, options: {}
        make_http_request :post, uri: uri, body: body, params: params, options: options
      end

      ##
      # Makes a PUT request
      #
      # @param uri [String] uri to send this request to
      # @param body [String] a body to send with the request, nil for requests without a body
      # @param params [Hash] query string parameters for the request
      # @param options [::Gapic::CallOptions,Hash] gapic options to be applied
      #     to the REST call. Currently only timeout and headers are supported.
      # @return [Faraday::Response]
      def make_put_request uri:, body: nil, params: {}, options: {}
        make_http_request :put, uri: uri, body: body, params: params, options: options
      end

      ##
      # @private
      # Sends a http request via Faraday
      # @param verb [Symbol] http verb
      # @param uri [String] uri to send this request to
      # @param body [String, nil] a body to send with the request, nil for requests without a body
      # @param params [Hash] query string parameters for the request
      # @param options [::Gapic::CallOptions,Hash] gapic options to be applied to the REST call.
      # @param is_server_streaming [Boolean] flag if method is streaming
      # @yieldparam chunk [String] The chunk of data received during server streaming.
      # @return [Faraday::Response]
      def make_http_request verb, uri:, body:, params:, options:, is_server_streaming: false, &block
        # Converts hash and nil to an options object
        options = ::Gapic::CallOptions.new(**options.to_h) unless options.is_a? ::Gapic::CallOptions
        deadline = calculate_deadline options
        retried_exception = nil
        next_timeout = get_timeout deadline

        begin
          base_make_http_request(verb: verb, uri: uri, body: body,
                                 params: params, metadata: options.metadata,
                                 timeout: next_timeout,
                                 is_server_streaming: is_server_streaming,
                                 &block)
        rescue ::Faraday::TimeoutError => e
          raise if @raise_faraday_errors
          raise Gapic::Rest::DeadlineExceededError.wrap_faraday_error e, root_cause: retried_exception
        rescue ::Faraday::Error => e
          next_timeout = get_timeout deadline

          if check_retry?(next_timeout) && options.retry_policy.call(e)
            retried_exception = e
            retry
          end

          raise if @raise_faraday_errors
          raise ::Gapic::Rest::Error.wrap_faraday_error e
        end
      end

      ##
      # @private
      # Sends a http request via Faraday
      #
      # @param verb [Symbol] http verb
      # @param uri [String] uri to send this request to
      # @param body [String, nil] a body to send with the request, nil for requests without a body
      # @param params [Hash] query string parameters for the request
      # @param metadata [Hash] additional headers for the request
      # @param is_server_streaming [Boolean] flag if method is streaming
      # @yieldparam chunk [String] The chunk of data received during server streaming.
      # @return [Faraday::Response]
      def base_make_http_request verb:, uri:, body:, params:, metadata:,
                                 timeout:, is_server_streaming: false
        if @numeric_enums && (!params.key?("$alt") || params["$alt"] == "json")
          params = params.merge({ "$alt" => "json;enum-encoding=int" })
        end

        @connection.send verb, uri do |req|
          req.params = params if params.any?
          req.body = body unless body.nil?
          req.headers = req.headers.merge metadata
          req.options.timeout = timeout if timeout&.positive?
          if is_server_streaming
            req.options.on_data = proc do |chunk, _overall_received_bytes|
              yield chunk
            end
          end
        end
      end

      private

      ##
      # Calculates deadline
      #
      # @param options [Gapic::CallOptions] call options for this call
      #
      # @return [Numeric, nil] Deadline against a POSIX clock_gettime()
      def calculate_deadline options
        return if options.timeout.nil?
        return if options.timeout.negative?

        Process.clock_gettime(Process::CLOCK_MONOTONIC) + options.timeout
      end

      ##
      # Calculates timeout (seconds) to use as a Faraday timeout
      #
      # @param deadline [Numeric, nil] deadline
      #
      # @return [Numeric, nil] Timeout (seconds)
      def get_timeout deadline
        return if deadline.nil?
        deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      ##
      # Whether the timeout should be retried
      #
      # @param timeout [Numeric, nil]
      #
      # @return [Boolean] whether the timeout should be retried
      def check_retry? timeout
        return true if timeout.nil?

        timeout.positive?
      end
    end
  end
end
