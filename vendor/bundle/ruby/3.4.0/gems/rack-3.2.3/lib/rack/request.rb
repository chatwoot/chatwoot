# frozen_string_literal: true

require_relative 'constants'
require_relative 'utils'
require_relative 'media_type'

module Rack
  # Rack::Request provides a convenient interface to a Rack
  # environment.  It is stateless, the environment +env+ passed to the
  # constructor will be directly modified.
  #
  #   req = Rack::Request.new(env)
  #   req.post?
  #   req.params["data"]

  class Request
    class << self
      attr_accessor :ip_filter

      # The priority when checking forwarded headers. The default
      # is <tt>[:forwarded, :x_forwarded]</tt>, which means, check the
      # +Forwarded+ header first, followed by the appropriate
      # <tt>X-Forwarded-*</tt> header.  You can revert the priority by
      # reversing the priority, or remove checking of either
      # or both headers by removing elements from the array.
      #
      # This should be set as appropriate in your environment
      # based on what reverse proxies are in use.  If you are not
      # using reverse proxies, you should probably use an empty
      # array.
      attr_accessor :forwarded_priority

      # The priority when checking either the <tt>X-Forwarded-Proto</tt>
      # or <tt>X-Forwarded-Scheme</tt> header for the forwarded protocol.
      # The default is <tt>[:proto, :scheme]</tt>, to try the
      # <tt>X-Forwarded-Proto</tt> header before the
      # <tt>X-Forwarded-Scheme</tt> header.  Rack 2 had behavior
      # similar to <tt>[:scheme, :proto]</tt>.  You can remove either or
      # both of the entries in array to ignore that respective header.
      attr_accessor :x_forwarded_proto_priority
    end

    @forwarded_priority = [:forwarded, :x_forwarded]
    @x_forwarded_proto_priority = [:proto, :scheme]

    valid_ipv4_octet = /\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])/

    trusted_proxies = Regexp.union(
      /\A127#{valid_ipv4_octet}{3}\z/,                          # localhost IPv4 range 127.x.x.x, per RFC-3330
      /\A::1\z/,                                                # localhost IPv6 ::1
      /\Af[cd][0-9a-f]{2}(?::[0-9a-f]{0,4}){0,7}\z/i,           # private IPv6 range fc00 .. fdff
      /\A10#{valid_ipv4_octet}{3}\z/,                           # private IPv4 range 10.x.x.x
      /\A172\.(1[6-9]|2[0-9]|3[01])#{valid_ipv4_octet}{2}\z/,   # private IPv4 range 172.16.0.0 .. 172.31.255.255
      /\A192\.168#{valid_ipv4_octet}{2}\z/,                     # private IPv4 range 192.168.x.x
      /\Alocalhost\z|\Aunix(\z|:)/i,                            # localhost hostname, and unix domain sockets
    )

    self.ip_filter = lambda { |ip| trusted_proxies.match?(ip) }

    ALLOWED_SCHEMES = %w(https http wss ws).freeze

    def initialize(env)
      @env = env
      @ip = nil
      @params = nil
    end

    def ip
      @ip ||= super
    end

    def params
      @params ||= super
    end

    def update_param(k, v)
      super
      @params = nil
    end

    def delete_param(k)
      v = super
      @params = nil
      v
    end

    module Env
      # The environment of the request.
      attr_reader :env

      def initialize(env)
        @env = env
        # This module is included at least in `ActionDispatch::Request`
        # The call to `super()` allows additional mixed-in initializers are called
        super()
      end

      # Predicate method to test to see if `name` has been set as request
      # specific data
      def has_header?(name)
        @env.key? name
      end

      # Get a request specific value for `name`.
      def get_header(name)
        @env[name]
      end

      # If a block is given, it yields to the block if the value hasn't been set
      # on the request.
      def fetch_header(name, &block)
        @env.fetch(name, &block)
      end

      # Loops through each key / value pair in the request specific data.
      def each_header(&block)
        @env.each(&block)
      end

      # Set a request specific value for `name` to `v`
      def set_header(name, v)
        @env[name] = v
      end

      # Add a header that may have multiple values.
      #
      # Example:
      #   request.add_header 'Accept', 'image/png'
      #   request.add_header 'Accept', '*/*'
      #
      #   assert_equal 'image/png,*/*', request.get_header('Accept')
      #
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
      def add_header(key, v)
        if v.nil?
          get_header key
        elsif has_header? key
          set_header key, "#{get_header key},#{v}"
        else
          set_header key, v
        end
      end

      # Delete a request specific value for `name`.
      def delete_header(name)
        @env.delete name
      end

      def initialize_copy(other)
        @env = other.env.dup
      end
    end

    module Helpers
      # The set of form-data media-types. Requests that do not indicate
      # one of the media types present in this list will not be eligible
      # for form-data / param parsing.
      FORM_DATA_MEDIA_TYPES = [
        'application/x-www-form-urlencoded',
        'multipart/form-data'
      ]

      # The set of media-types. Requests that do not indicate
      # one of the media types present in this list will not be eligible
      # for param parsing like soap attachments or generic multiparts
      PARSEABLE_DATA_MEDIA_TYPES = [
        'multipart/related',
        'multipart/mixed'
      ]

      # Default ports depending on scheme. Used to decide whether or not
      # to include the port in a generated URI.
      DEFAULT_PORTS = { 'http' => 80, 'https' => 443, 'coffee' => 80 }

      # The address of the client which connected to the proxy.
      HTTP_X_FORWARDED_FOR = 'HTTP_X_FORWARDED_FOR'

      # The contents of the host/:authority header sent to the proxy.
      HTTP_X_FORWARDED_HOST = 'HTTP_X_FORWARDED_HOST'

      HTTP_FORWARDED          = 'HTTP_FORWARDED'

      # The value of the scheme sent to the proxy.
      HTTP_X_FORWARDED_SCHEME = 'HTTP_X_FORWARDED_SCHEME'

      # The protocol used to connect to the proxy.
      HTTP_X_FORWARDED_PROTO = 'HTTP_X_FORWARDED_PROTO'

      # The port used to connect to the proxy.
      HTTP_X_FORWARDED_PORT = 'HTTP_X_FORWARDED_PORT'

      # Another way for specifying https scheme was used.
      HTTP_X_FORWARDED_SSL = 'HTTP_X_FORWARDED_SSL'

      def body;            get_header(RACK_INPUT)                         end
      def script_name;     get_header(SCRIPT_NAME).to_s                   end
      def script_name=(s); set_header(SCRIPT_NAME, s.to_s)                end

      def path_info;       get_header(PATH_INFO).to_s                     end
      def path_info=(s);   set_header(PATH_INFO, s.to_s)                  end

      def request_method;  get_header(REQUEST_METHOD)                     end
      def query_string;    get_header(QUERY_STRING).to_s                  end
      def content_length;  get_header('CONTENT_LENGTH')                   end
      def logger;          get_header(RACK_LOGGER)                        end
      def user_agent;      get_header('HTTP_USER_AGENT')                  end

      # the referer of the client
      def referer;         get_header('HTTP_REFERER')                     end
      alias referrer referer

      def session
        fetch_header(RACK_SESSION) do |k|
          set_header RACK_SESSION, default_session
        end
      end

      def session_options
        fetch_header(RACK_SESSION_OPTIONS) do |k|
          set_header RACK_SESSION_OPTIONS, {}
        end
      end

      # Checks the HTTP request method (or verb) to see if it was of type DELETE
      def delete?;  request_method == DELETE  end

      # Checks the HTTP request method (or verb) to see if it was of type GET
      def get?;     request_method == GET     end

      # Checks the HTTP request method (or verb) to see if it was of type HEAD
      def head?;    request_method == HEAD    end

      # Checks the HTTP request method (or verb) to see if it was of type OPTIONS
      def options?; request_method == OPTIONS end

      # Checks the HTTP request method (or verb) to see if it was of type LINK
      def link?;    request_method == LINK    end

      # Checks the HTTP request method (or verb) to see if it was of type PATCH
      def patch?;   request_method == PATCH   end

      # Checks the HTTP request method (or verb) to see if it was of type POST
      def post?;    request_method == POST    end

      # Checks the HTTP request method (or verb) to see if it was of type PUT
      def put?;     request_method == PUT     end

      # Checks the HTTP request method (or verb) to see if it was of type TRACE
      def trace?;   request_method == TRACE   end

      # Checks the HTTP request method (or verb) to see if it was of type UNLINK
      def unlink?;  request_method == UNLINK  end

      def scheme
        if get_header(HTTPS) == 'on'
          'https'
        elsif get_header(HTTP_X_FORWARDED_SSL) == 'on'
          'https'
        elsif forwarded_scheme
          forwarded_scheme
        else
          get_header(RACK_URL_SCHEME)
        end
      end

      # The authority of the incoming request as defined by RFC3976.
      # https://tools.ietf.org/html/rfc3986#section-3.2
      #
      # In HTTP/1, this is the `host` header.
      # In HTTP/2, this is the `:authority` pseudo-header.
      def authority
        forwarded_authority || host_authority || server_authority
      end

      # The authority as defined by the `SERVER_NAME` and `SERVER_PORT`
      # variables.
      def server_authority
        host = self.server_name
        port = self.server_port

        if host
          if port
            "#{host}:#{port}"
          else
            host
          end
        end
      end

      def server_name
        get_header(SERVER_NAME)
      end

      def server_port
        get_header(SERVER_PORT)
      end

      def cookies
        hash = fetch_header(RACK_REQUEST_COOKIE_HASH) do |key|
          set_header(key, {})
        end

        string = get_header(HTTP_COOKIE)

        unless string == get_header(RACK_REQUEST_COOKIE_STRING)
          hash.replace Utils.parse_cookies_header(string)
          set_header(RACK_REQUEST_COOKIE_STRING, string)
        end

        hash
      end

      def content_type
        content_type = get_header('CONTENT_TYPE')
        content_type.nil? || content_type.empty? ? nil : content_type
      end

      def xhr?
        get_header("HTTP_X_REQUESTED_WITH") == "XMLHttpRequest"
      end

      # The `HTTP_HOST` header.
      def host_authority
        get_header(HTTP_HOST)
      end

      def host_with_port(authority = self.authority)
        host, _, port = split_authority(authority)

        if port == DEFAULT_PORTS[self.scheme]
          host
        else
          authority
        end
      end

      # Returns a formatted host, suitable for being used in a URI.
      def host
        split_authority(self.authority)[0]
      end

      # Returns an address suitable for being to resolve to an address.
      # In the case of a domain name or IPv4 address, the result is the same
      # as +host+. In the case of IPv6 or future address formats, the square
      # brackets are removed.
      def hostname
        split_authority(self.authority)[1]
      end

      def port
        if authority = self.authority
          _, _, port = split_authority(authority)
        end

        port || forwarded_port&.last || DEFAULT_PORTS[scheme] || server_port
      end

      def forwarded_for
        forwarded_priority.each do |type|
          case type
          when :forwarded
            if forwarded_for = get_http_forwarded(:for)
              return(forwarded_for.map! do |authority|
                split_authority(authority)[1]
              end)
            end
          when :x_forwarded
            if value = get_header(HTTP_X_FORWARDED_FOR)
              return(split_header(value).map do |authority|
                split_authority(wrap_ipv6(authority))[1]
              end)
            end
          end
        end

        nil
      end

      def forwarded_port
        forwarded_priority.each do |type|
          case type
          when :forwarded
            if forwarded = get_http_forwarded(:for)
              return(forwarded.map do |authority|
                split_authority(authority)[2]
              end.compact)
            end
          when :x_forwarded
            if value = get_header(HTTP_X_FORWARDED_PORT)
              return split_header(value).map(&:to_i)
            end
          end
        end

        nil
      end

      def forwarded_authority
        forwarded_priority.each do |type|
          case type
          when :forwarded
            if forwarded = get_http_forwarded(:host)
              return forwarded.last
            end
          when :x_forwarded
            if (value = get_header(HTTP_X_FORWARDED_HOST)) && (x_forwarded_host = split_header(value).last)
              return wrap_ipv6(x_forwarded_host)
            end
          end
        end

        nil
      end

      def ssl?
        scheme == 'https' || scheme == 'wss'
      end

      def ip
        remote_addresses = split_header(get_header('REMOTE_ADDR'))

        remote_addresses.reverse_each do |ip|
          return ip unless trusted_proxy?(ip)
        end

        if (forwarded_for = self.forwarded_for) && !forwarded_for.empty?
          # The forwarded for addresses are ordered: client, proxy1, proxy2.
          # So we reject all the trusted addresses (proxy*) and return the
          # last client. Or if we trust everyone, we just return the first
          # address.
          forwarded_for.reverse_each do |ip|
            return ip unless trusted_proxy?(ip)
          end
          return forwarded_for.first
        end

        # If all the addresses are trusted, and we aren't forwarded, just return
        # the first remote address, which represents the source of the request.
        remote_addresses.first
      end

      # The media type (type/subtype) portion of the CONTENT_TYPE header
      # without any media type parameters. e.g., when CONTENT_TYPE is
      # "text/plain;charset=utf-8", the media-type is "text/plain".
      #
      # For more information on the use of media types in HTTP, see:
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7
      def media_type
        MediaType.type(content_type)
      end

      # The media type parameters provided in CONTENT_TYPE as a Hash, or
      # an empty Hash if no CONTENT_TYPE or media-type parameters were
      # provided.  e.g., when the CONTENT_TYPE is "text/plain;charset=utf-8",
      # this method responds with the following Hash:
      #   { 'charset' => 'utf-8' }
      def media_type_params
        MediaType.params(content_type)
      end

      # The character set of the request body if a "charset" media type
      # parameter was given, or nil if no "charset" was specified. Note
      # that, per RFC2616, text/* media types that specify no explicit
      # charset are to be considered ISO-8859-1.
      def content_charset
        media_type_params['charset']
      end

      # Determine whether the request body contains form-data by checking
      # the request content-type for one of the media-types:
      # "application/x-www-form-urlencoded" or "multipart/form-data". The
      # list of form-data media types can be modified through the
      # +FORM_DATA_MEDIA_TYPES+ array.
      #
      # A request body is also assumed to contain form-data when no
      # content-type header is provided and the request_method is POST.
      def form_data?
        type = media_type
        meth = get_header(RACK_METHODOVERRIDE_ORIGINAL_METHOD) || get_header(REQUEST_METHOD)

        (meth == POST && type.nil?) || FORM_DATA_MEDIA_TYPES.include?(type)
      end

      # Determine whether the request body contains data by checking
      # the request media_type against registered parse-data media-types
      def parseable_data?
        PARSEABLE_DATA_MEDIA_TYPES.include?(media_type)
      end

      # Returns the data received in the query string.
      def GET
        get_header(RACK_REQUEST_QUERY_HASH) || set_header(RACK_REQUEST_QUERY_HASH, parse_query(query_string, '&'))
      end

      # Returns the form data pairs received in the request body.
      #
      # This method support both application/x-www-form-urlencoded and
      # multipart/form-data.
      def form_pairs
        if pairs = get_header(RACK_REQUEST_FORM_PAIRS)
          return pairs
        elsif error = get_header(RACK_REQUEST_FORM_ERROR)
          raise error.class, error.message, cause: error.cause
        end

        begin
          rack_input = get_header(RACK_INPUT)

          # Otherwise, figure out how to parse the input:
          if rack_input.nil?
            set_header(RACK_REQUEST_FORM_PAIRS, [])
          elsif form_data? || parseable_data?
            if pairs = Rack::Multipart.parse_multipart(env, Rack::Multipart::ParamList)
              set_header RACK_REQUEST_FORM_PAIRS, pairs
            else
              # Add 2 bytes. One to check whether it is over the limit, and a second
              # in case the slice! call below removes the last byte
              # If read returns nil, use the empty string
              form_vars = get_header(RACK_INPUT).read(query_parser.bytesize_limit + 2) || ''

              # Fix for Safari Ajax postings that always append \0
              # form_vars.sub!(/\0\z/, '') # performance replacement:
              form_vars.slice!(-1) if form_vars.end_with?("\0")

              set_header RACK_REQUEST_FORM_VARS, form_vars
              pairs = query_parser.parse_query_pairs(form_vars, '&')
              set_header(RACK_REQUEST_FORM_PAIRS, pairs)
            end
          else
            set_header(RACK_REQUEST_FORM_PAIRS, [])
          end
        rescue => error
          set_header(RACK_REQUEST_FORM_ERROR, error)
          raise
        end
      end

      # Returns the data received in the request body.
      #
      # This method support both application/x-www-form-urlencoded and
      # multipart/form-data.
      def POST
        if form_hash = get_header(RACK_REQUEST_FORM_HASH)
          return form_hash
        elsif error = get_header(RACK_REQUEST_FORM_ERROR)
          raise error.class, error.message, cause: error.cause
        end

        pairs = form_pairs
        set_header RACK_REQUEST_FORM_HASH, expand_param_pairs(pairs)
      end

      # The union of GET and POST data.
      #
      # Note that modifications will not be persisted in the env. Use update_param or delete_param if you want to destructively modify params.
      def params
        self.GET.merge(self.POST)
      end

      # Allow overriding the query parser that the receiver will use.
      # By default Rack::Utils.default_query_parser is used.
      attr_writer :query_parser

      # Destructively update a parameter, whether it's in GET and/or POST. Returns nil.
      #
      # The parameter is updated wherever it was previous defined, so GET, POST, or both. If it wasn't previously defined, it's inserted into GET.
      #
      # <tt>env['rack.input']</tt> is not touched.
      def update_param(k, v)
        found = false
        if self.GET.has_key?(k)
          found = true
          self.GET[k] = v
        end
        if self.POST.has_key?(k)
          found = true
          self.POST[k] = v
        end
        unless found
          self.GET[k] = v
        end
      end

      # Destructively delete a parameter, whether it's in GET or POST. Returns the value of the deleted parameter.
      #
      # If the parameter is in both GET and POST, the POST value takes precedence since that's how #params works.
      #
      # <tt>env['rack.input']</tt> is not touched.
      def delete_param(k)
        post_value, get_value = self.POST.delete(k), self.GET.delete(k)
        post_value || get_value
      end

      def base_url
        "#{scheme}://#{host_with_port}"
      end

      # Tries to return a remake of the original request URL as a string.
      def url
        base_url + fullpath
      end

      def path
        script_name + path_info
      end

      def fullpath
        query_string.empty? ? path : "#{path}?#{query_string}"
      end

      def accept_encoding
        parse_http_accept_header(get_header("HTTP_ACCEPT_ENCODING"))
      end

      def accept_language
        parse_http_accept_header(get_header("HTTP_ACCEPT_LANGUAGE"))
      end

      def trusted_proxy?(ip)
        Rack::Request.ip_filter.call(ip)
      end

      private

      def default_session; {}; end

      # Assist with compatibility when processing `X-Forwarded-For`.
      def wrap_ipv6(host)
        # Even thought IPv6 addresses should be wrapped in square brackets,
        # sometimes this is not done in various legacy/underspecified headers.
        # So we try to fix this situation for compatibility reasons.

        # Try to detect IPv6 addresses which aren't escaped yet:
        if !host.start_with?('[') && host.count(':') > 1
          "[#{host}]"
        else
          host
        end
      end

      def parse_http_accept_header(header)
        # It would be nice to use filter_map here, but it's Ruby 2.7+
        parts = header.to_s.split(',')

        parts.map! do |part|
          part.strip!
          next if part.empty?

          attribute, parameters = part.split(';', 2)
          attribute.strip!
          parameters&.strip!
          quality = 1.0
          if parameters and /\Aq=([\d.]+)/ =~ parameters
            quality = $1.to_f
          end
          [attribute, quality]
        end

        parts.compact!

        parts
      end

      # Get an array of values set in the RFC 7239 `Forwarded` request header.
      def get_http_forwarded(token)
        Utils.forwarded_values(get_header(HTTP_FORWARDED))&.[](token)
      end

      def query_parser
        @query_parser || Utils.default_query_parser
      end

      def parse_query(qs, d = '&')
        query_parser.parse_nested_query(qs, d)
      end

      def parse_multipart
        warn "Rack::Request#parse_multipart is deprecated and will be removed in a future version of Rack.", uplevel: 1
        Rack::Multipart.extract_multipart(self, query_parser)
      end

      def expand_param_pairs(pairs, query_parser = query_parser())
        params = query_parser.make_params

        pairs.each do |k, v|
          query_parser.normalize_params(params, k, v)
        end

        params.to_params_hash
      end

      def split_header(value)
        value ? value.strip.split(/[, \t]+/) : []
      end

      # ipv6 extracted from resolv stdlib, simplified
      # to remove numbered match group creation.
      ipv6 = Regexp.union(
        /(?:[0-9A-Fa-f]{1,4}:){7}
         [0-9A-Fa-f]{1,4}/x,
        /(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)? ::
         (?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?/x,
        /(?:[0-9A-Fa-f]{1,4}:){6,6}
         \d+\.\d+\.\d+\.\d+/x,
        /(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)? ::
         (?:[0-9A-Fa-f]{1,4}:)*
         \d+\.\d+\.\d+\.\d+/x,
        /[Ff][Ee]80
         (?::[0-9A-Fa-f]{1,4}){7}
         %[-0-9A-Za-z._~]+/x,
        /[Ff][Ee]80:
         (?:
           (?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)? ::
           (?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?
           |
           :(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?
         )?
         :[0-9A-Fa-f]{1,4}%[-0-9A-Za-z._~]+/x)

      AUTHORITY = /
        \A
        (?<host>
          # Match IPv6 as a string of hex digits and colons in square brackets
          \[(?<address>#{ipv6})\]
          |
          # Match any other printable string (except square brackets) as a hostname
          (?<address>[[[:graph:]&&[^\[\]]]]*?)
        )
        (:(?<port>\d+))?
        \z
      /x

      private_constant :AUTHORITY

      def split_authority(authority)
        return [] if authority.nil?
        return [] unless match = AUTHORITY.match(authority)
        return match[:host], match[:address], match[:port]&.to_i
      end

      FORWARDED_SCHEME_HEADERS = {
        proto: HTTP_X_FORWARDED_PROTO,
        scheme: HTTP_X_FORWARDED_SCHEME
      }.freeze
      private_constant :FORWARDED_SCHEME_HEADERS
      def forwarded_scheme
        forwarded_priority.each do |type|
          case type
          when :forwarded
            if (forwarded_proto = get_http_forwarded(:proto)) &&
               (scheme = allowed_scheme(forwarded_proto.last))
              return scheme
            end
          when :x_forwarded
            x_forwarded_proto_priority.each do |x_type|
              if header = FORWARDED_SCHEME_HEADERS[x_type]
                split_header(get_header(header)).reverse_each do |scheme|
                  if allowed_scheme(scheme)
                    return scheme
                  end
                end
              end
            end
          end
        end

        nil
      end

      def allowed_scheme(header)
        header if ALLOWED_SCHEMES.include?(header)
      end

      def forwarded_priority
        Request.forwarded_priority
      end

      def x_forwarded_proto_priority
        Request.x_forwarded_proto_priority
      end
    end

    include Env
    include Helpers
  end
end

# :nocov:
require_relative 'multipart' unless defined?(Rack::Multipart)
# :nocov:
