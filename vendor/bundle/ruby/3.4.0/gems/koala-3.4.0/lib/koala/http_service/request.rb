module Koala
  module HTTPService
    class Request
      attr_reader :raw_path, :raw_args, :raw_verb, :raw_options

      # @param path the server path for this request
      # @param args (see Koala::Facebook::API#api)
      # @param verb the HTTP method to use.
      #             If not get or post, this will be turned into a POST request with the appropriate :method
      #             specified in the arguments.
      # @param options various flags to indicate which server to use. (see Koala::Facebook::API#api)
      # @param options
      # @option options :video use the server designated for video uploads
      # @option options :beta use the beta tier
      # @option options :use_ssl force https, even if not needed
      # @option options :json whether or not to send JSON to Facebook
      def initialize(path:, verb:, args: {}, options: {})
        @raw_path = path
        @raw_args = args
        @raw_verb = verb
        @raw_options = options
      end

      # Determines which type of request to send to Facebook. Facebook natively accepts GETs and POSTs, for others we have to include the method in the post body.
      #
      # @return one of get or post
      def verb
        ["get", "post"].include?(raw_verb) ? raw_verb : "post"
      end

      # Determines the path to be requested on Facebook, incorporating an API version if specified.
      #
      # @return the original path, with API version if appropriate.
      def path
        # if an api_version is specified and the path does not already contain
        # one, prepend it to the path
        api_version = raw_options[:api_version] || Koala.config.api_version
        if api_version && !path_contains_api_version?
          begins_with_slash = raw_path[0] == "/"
          divider = begins_with_slash ? "" : "/"
          "/#{api_version}#{divider}#{raw_path}"
        else
          raw_path
        end
      end

      # Determines any arguments to be sent in a POST body.
      #
      # @return {} for GET; the provided args for POST; those args with the method parameter for
      # other values
      def post_args
        if raw_verb == "get"
          {}
        elsif raw_verb == "post"
          args
        else
          args.merge(method: raw_verb)
        end
      end

      def get_args
        raw_verb == "get" ? args : {}
      end

      # Calculates a set of request options to pass to Faraday.
      #
      # @return a hash combining GET parameters (if appropriate), default options, and
      # any specified for the request.
      def options
        # figure out our options for this request
        add_ssl_options(
          # for GETs, we pass the params to Faraday to encode
          {params: get_args}.merge(HTTPService.http_options).merge(raw_options)
        )
      end

      # Whether or not this request should use JSON.
      #
      # @return true or false
      def json?
        raw_options[:format] == :json
      end

      # The address of the appropriate Facebook server.
      #
      # @return a complete server address with protocol
      def server
        uri = "#{options[:use_ssl] ? "https" : "http"}://#{Koala.config.graph_server}"
        # if we want to use the beta tier or the video server, make those substitutions as
        # appropriate
        replace_server_component(
          replace_server_component(uri, options[:video], Koala.config.video_replace),
          options[:beta],
          Koala.config.beta_replace
        )
      end

      protected

      # The arguments to include in the request.
      def args
        raw_args.inject({}) do |hash, (key, value)|
          # Resolve UploadableIOs into data Facebook can work with
          hash.merge(key => value.is_a?(UploadableIO) ? value.to_upload_io : value)
        end
      end

      def add_ssl_options(opts)
        # require https by default (can be overriden by explicitly setting other SSL options)
        {
          use_ssl: true,
          ssl: {verify: true}.merge(opts[:ssl] || {})
        }.merge(opts)
      end

      # Determines whether a given path already contains an API version.
      #
      # @param path the URL path.
      #
      # @return true or false accordingly.
      def path_contains_api_version?
        # looks for "/$MAJOR[.$MINOR]/" in the path
        match = /^\/?(v\d+(?:\.\d+)?)\//.match(raw_path)
        !!(match && match[1])
      end

      def replace_server_component(host, condition_met, replacement)
        return host unless condition_met
        host.gsub(Koala.config.host_path_matcher, replacement)
      end
    end
  end
end
