require 'faraday'
require 'faraday/multipart' unless defined? Faraday::FilePart # hack for faraday < 1.9 to avoid warnings
require 'koala/http_service/uploadable_io'
require 'koala/http_service/response'
require 'koala/http_service/request'

module Koala
  module HTTPService
    class << self
      # A customized stack of Faraday middleware that will be used to make each request.
      attr_accessor :faraday_middleware
      # A default set of HTTP options (see https://github.com/arsduo/koala/wiki/HTTP-Services)
      attr_accessor :http_options
    end

    @http_options ||= {}

    # Koala's default middleware stack.
    # We encode requests in a Facebook-compatible multipart request,
    # and use whichever adapter has been configured for this application.
    DEFAULT_MIDDLEWARE = Proc.new do |builder|
      builder.request :multipart
      builder.request :url_encoded
      builder.adapter Faraday.default_adapter
    end

    # Default server information for Facebook. These can be overridden by setting config values.
    # See Koala.config.
    DEFAULT_SERVERS = {
      :graph_server => 'graph.facebook.com',
      :dialog_host => 'www.facebook.com',
      :host_path_matcher => /\.facebook/,
      :video_replace => '-video.facebook',
      :beta_replace => '.beta.facebook'
    }

    # Makes a request directly to Facebook.
    # @note You'll rarely need to call this method directly.
    #
    # @see Koala::Facebook::API#api
    # @see Koala::Facebook::GraphAPIMethods#graph_call
    #
    # @param request a Koala::HTTPService::Request object
    #
    # @raise an appropriate connection error if unable to make the request to Facebook
    #
    # @return [Koala::HTTPService::Response] a response object representing the results from Facebook
    def self.make_request(request)
      # set up our Faraday connection
      conn = Faraday.new(request.server, faraday_options(request.options), &(faraday_middleware || DEFAULT_MIDDLEWARE))

      filtered_args = request.raw_args.dup.transform_keys(&:to_s)

      if Koala.config.mask_tokens
        %w(access_token input_token).each do |arg_token|
          if (token = filtered_args[arg_token])
            filtered_args[arg_token] = token[0, 10] + '*****' + token[-5, 5]
          end
        end
      end

      Koala::Utils.debug "STARTED => #{request.verb.upcase}: #{request.path} params: #{filtered_args.inspect}"

      if request.verb == "post" && request.json?
        # JSON requires a bit more handling
        # remember, all non-GET requests are turned into POSTs, so this covers everything but GETs
        response = conn.post do |req|
          req.path = request.path
          req.headers["Content-Type"] = "application/json"
          req.body = request.post_args.to_json
          req
        end
      else
        response = conn.send(request.verb, request.path, request.post_args)
      end

      Koala::Utils.debug "FINISHED => #{request.verb.upcase}: #{request.path} params: #{filtered_args.inspect}"
      Koala::HTTPService::Response.new(response.status.to_i, response.body, response.headers)
    end

    # Encodes a given hash into a query string.
    # This is used mainly by the Batch API nowadays, since Faraday handles this for regular cases.
    #
    # @param params_hash a hash of values to CGI-encode and appropriately join
    #
    # @example
    #   Koala.http_service.encode_params({:a => 2, :b => "My String"})
    #   => "a=2&b=My+String"
    #
    # @return the appropriately-encoded string
    def self.encode_params(param_hash)
      ((param_hash || {}).sort_by{|k, v| k.to_s}.collect do |key_and_value|
        value = key_and_value[1]
        unless value.is_a? String
          value = value.to_json
        end
        "#{key_and_value[0].to_s}=#{CGI.escape value}"
      end).join("&")
    end

    private

    def self.faraday_options(options)
      valid_options = [:request, :proxy, :ssl, :builder, :url, :parallel_manager, :params, :headers, :builder_class]
      Hash[ options.select { |key,value| valid_options.include?(key) } ]
    end
  end
end
