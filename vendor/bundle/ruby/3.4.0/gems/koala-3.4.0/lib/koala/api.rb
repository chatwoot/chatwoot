# graph_batch_api and legacy are required at the bottom, since they depend on API being defined
require 'koala/api/graph_api_methods'
require 'koala/api/graph_collection'
require 'openssl'

module Koala
  module Facebook
    class API
      # Creates a new API client.
      # @param [String] access_token access token
      # @param [String] app_secret app secret, for tying your access tokens to your app secret
      #                 If you provide an app secret, your requests will be
      #                 signed by default, unless you pass appsecret_proof:
      #                 false as an option to the API call. (See
      #                 https://developers.facebook.com/docs/graph-api/securing-requests/)
      # @param [Block]  rate_limit_hook block called with limits received in facebook response headers
      # @note If no access token is provided, you can only access some public information.
      # @return [Koala::Facebook::API] the API client
      def initialize(access_token = Koala.config.access_token, app_secret = Koala.config.app_secret, rate_limit_hook = Koala.config.rate_limit_hook)
        @access_token = access_token
        @app_secret = app_secret
        @rate_limit_hook = rate_limit_hook
      end

      attr_reader :access_token, :app_secret, :rate_limit_hook

      include GraphAPIMethods

      # Make a call directly to the Graph API.
      # (See any of the other methods for example invocations.)
      #
      # @param path the Graph API path to query (no leading / needed)
      # @param args (see #get_object)
      # @param verb the type of HTTP request to make (get, post, delete, etc.)
      # @options (see #get_object)
      #
      # @yield response when making a batch API call, you can pass in a block
      #        that parses the results, allowing for cleaner code.
      #        The block's return value is returned in the batch results.
      #        See the code for {#get_picture} for examples.
      #        (Not needed in regular calls; you'll probably rarely use this.)
      #
      # @raise [Koala::Facebook::APIError] if Facebook returns an error
      #
      # @return the result from Facebook
      def graph_call(path, args = {}, verb = "get", options = {}, &post_processing)
        # enable appsecret_proof by default
        options = {:appsecret_proof => true}.merge(options) if @app_secret
        response = api(path, args, verb, options)

        error = GraphErrorChecker.new(response.status, response.body, response.headers).error_if_appropriate
        raise error if error

        # if we want a component other than the body (e.g. redirect header for images), provide that
        http_component = options[:http_component]
        desired_data = if options[:http_component]
          http_component == :response ? response : response.send(http_component)
        else
          # turn this into a GraphCollection if it's pageable
          API::GraphCollection.evaluate(response, self)
        end

        if rate_limit_hook
          limits = %w(x-business-use-case-usage x-ad-account-usage x-app-usage).each_with_object({}) do |key, hash|
            value = response.headers.fetch(key, nil)
            next unless value
            hash[key] = JSON.parse(response.headers[key])
          rescue JSON::ParserError => e
            Koala::Utils.logger.error("#{e.class}: #{e.message} while parsing #{key} = #{value}")
          end

          rate_limit_hook.call(limits) if limits.keys.any?
        end

        # now process as appropriate for the given call (get picture header, etc.)
        post_processing ? post_processing.call(desired_data) : desired_data
      end


      # Makes a request to the appropriate Facebook API.
      # @note You'll rarely need to call this method directly.
      #
      # @see GraphAPIMethods#graph_call
      #
      # @param path the server path for this request (leading / is prepended if not present)
      # @param args arguments to be sent to Facebook
      # @param verb the HTTP method to use
      # @param options request-related options for Koala and Faraday.
      #                See https://github.com/arsduo/koala/wiki/HTTP-Services for additional options.
      # @option options [Symbol] :http_component which part of the response (headers, body, or status) to return
      # @option options [Symbol] :format which request format to use. Currently, :json is supported
      # @option options [Symbol] :preserve_form_arguments preserve arrays in arguments, which are
      #                          expected by certain FB APIs (see the ads API in particular,
      #                          https://developers.facebook.com/docs/marketing-api/adgroup/v2.4)
      # @option options [Boolean] :beta use Facebook's beta tier
      # @option options [Boolean] :use_ssl force SSL for this request, even if it's tokenless.
      #                                    (All API requests with access tokens use SSL.)
      # @raise [Koala::Facebook::ServerError] if Facebook returns an error (response status >= 500)
      #
      # @return a Koala::HTTPService::Response object representing the returned Facebook data
      def api(path, args = {}, verb = "get", options = {})
        # we make a copy of args so the modifications (added access_token & appsecret_proof)
        # do not affect the received argument
        args = args.dup

        # If a access token is explicitly provided, use that
        # This is explicitly needed in batch requests so GraphCollection
        # results preserve any specific access tokens provided
        args["access_token"] ||= @access_token || @app_access_token if @access_token || @app_access_token

        if options.delete(:appsecret_proof) && args["access_token"] && @app_secret
          args["appsecret_proof"] = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @app_secret, args["access_token"])
        end

        # Translate any arrays in the params into comma-separated strings
        args = sanitize_request_parameters(args) unless preserve_form_arguments?(options)

        # add a leading / if needed...
        path = "/#{path}" unless path.to_s =~ /^\//

        # make the request via the provided service
        result = Koala.make_request(path, args, verb, options)

        if result.status.to_i >= 500
          raise Koala::Facebook::ServerError.new(result.status.to_i, result.body)
        end

        result
      end

      private

      # Sanitizes Ruby objects into Facebook-compatible string values.
      #
      # @param parameters a hash of parameters.
      #
      # Returns a hash in which values that are arrays of non-enumerable values
      #         (Strings, Symbols, Numbers, etc.) are turned into comma-separated strings.
      def sanitize_request_parameters(parameters)
        parameters.reduce({}) do |result, (key, value)|
          # if the parameter is an array that contains non-enumerable values,
          # turn it into a comma-separated list
          # in Ruby 1.8.7, strings are enumerable, but we don't care
          if value.is_a?(Array) && value.none? {|entry| entry.is_a?(Enumerable) && !entry.is_a?(String)}
            value = value.join(",")
          end
          result.merge(key => value)
        end
      end

      def preserve_form_arguments?(options)
        options[:format] == :json || options[:preserve_form_arguments] || Koala.config.preserve_form_arguments
      end

      def check_response(http_status, body, headers)
      end
    end
  end
end
