require 'tempfile'
require 'cgi'
require 'netrc'
require 'set'

begin
  # Use mime/types/columnar if available, for reduced memory usage
  require 'mime/types/columnar'
rescue LoadError
  require 'mime/types'
end

module RestClient
  # This class is used internally by RestClient to send the request, but you can also
  # call it directly if you'd like to use a method not supported by the
  # main API.  For example:
  #
  #   RestClient::Request.execute(:method => :head, :url => 'http://example.com')
  #
  # Mandatory parameters:
  # * :method
  # * :url
  # Optional parameters (have a look at ssl and/or uri for some explanations):
  # * :headers a hash containing the request headers
  # * :cookies may be a Hash{String/Symbol => String} of cookie values, an
  #     Array<HTTP::Cookie>, or an HTTP::CookieJar containing cookies. These
  #     will be added to a cookie jar before the request is sent.
  # * :user and :password for basic auth, will be replaced by a user/password available in the :url
  # * :block_response call the provided block with the HTTPResponse as parameter
  # * :raw_response return a low-level RawResponse instead of a Response
  # * :log Set the log for this request only, overriding RestClient.log, if
  #      any.
  # * :stream_log_percent (Only relevant with :raw_response => true) Customize
  #     the interval at which download progress is logged. Defaults to every
  #     10% complete.
  # * :max_redirects maximum number of redirections (default to 10)
  # * :proxy An HTTP proxy URI to use for this request. Any value here
  #   (including nil) will override RestClient.proxy.
  # * :verify_ssl enable ssl verification, possible values are constants from
  #     OpenSSL::SSL::VERIFY_*, defaults to OpenSSL::SSL::VERIFY_PEER
  # * :read_timeout and :open_timeout are how long to wait for a response and
  #     to open a connection, in seconds. Pass nil to disable the timeout.
  # * :timeout can be used to set both timeouts
  # * :ssl_client_cert, :ssl_client_key, :ssl_ca_file, :ssl_ca_path,
  #     :ssl_cert_store, :ssl_verify_callback, :ssl_verify_callback_warnings
  # * :ssl_version specifies the SSL version for the underlying Net::HTTP connection
  # * :ssl_ciphers sets SSL ciphers for the connection. See
  #     OpenSSL::SSL::SSLContext#ciphers=
  # * :before_execution_proc a Proc to call before executing the request. This
  #      proc, like procs from RestClient.before_execution_procs, will be
  #      called with the HTTP request and request params.
  class Request

    attr_reader :method, :uri, :url, :headers, :payload, :proxy,
                :user, :password, :read_timeout, :max_redirects,
                :open_timeout, :raw_response, :processed_headers, :args,
                :ssl_opts

    # An array of previous redirection responses
    attr_accessor :redirection_history

    def self.execute(args, & block)
      new(args).execute(& block)
    end

    SSLOptionList = %w{client_cert client_key ca_file ca_path cert_store
                       version ciphers verify_callback verify_callback_warnings}

    def inspect
      "<RestClient::Request @method=#{@method.inspect}, @url=#{@url.inspect}>"
    end

    def initialize args
      @method = normalize_method(args[:method])
      @headers = (args[:headers] || {}).dup
      if args[:url]
        @url = process_url_params(normalize_url(args[:url]), headers)
      else
        raise ArgumentError, "must pass :url"
      end

      @user = @password = nil
      parse_url_with_auth!(url)

      # process cookie arguments found in headers or args
      @cookie_jar = process_cookie_args!(@uri, @headers, args)

      @payload = Payload.generate(args[:payload])

      @user = args[:user] if args.include?(:user)
      @password = args[:password] if args.include?(:password)

      if args.include?(:timeout)
        @read_timeout = args[:timeout]
        @open_timeout = args[:timeout]
      end
      if args.include?(:read_timeout)
        @read_timeout = args[:read_timeout]
      end
      if args.include?(:open_timeout)
        @open_timeout = args[:open_timeout]
      end
      @block_response = args[:block_response]
      @raw_response = args[:raw_response] || false

      @stream_log_percent = args[:stream_log_percent] || 10
      if @stream_log_percent <= 0 || @stream_log_percent > 100
        raise ArgumentError.new(
          "Invalid :stream_log_percent #{@stream_log_percent.inspect}")
      end

      @proxy = args.fetch(:proxy) if args.include?(:proxy)

      @ssl_opts = {}

      if args.include?(:verify_ssl)
        v_ssl = args.fetch(:verify_ssl)
        if v_ssl
          if v_ssl == true
            # interpret :verify_ssl => true as VERIFY_PEER
            @ssl_opts[:verify_ssl] = OpenSSL::SSL::VERIFY_PEER
          else
            # otherwise pass through any truthy values
            @ssl_opts[:verify_ssl] = v_ssl
          end
        else
          # interpret all falsy :verify_ssl values as VERIFY_NONE
          @ssl_opts[:verify_ssl] = OpenSSL::SSL::VERIFY_NONE
        end
      else
        # if :verify_ssl was not passed, default to VERIFY_PEER
        @ssl_opts[:verify_ssl] = OpenSSL::SSL::VERIFY_PEER
      end

      SSLOptionList.each do |key|
        source_key = ('ssl_' + key).to_sym
        if args.has_key?(source_key)
          @ssl_opts[key.to_sym] = args.fetch(source_key)
        end
      end

      # Set some other default SSL options, but only if we have an HTTPS URI.
      if use_ssl?

        # If there's no CA file, CA path, or cert store provided, use default
        if !ssl_ca_file && !ssl_ca_path && !@ssl_opts.include?(:cert_store)
          @ssl_opts[:cert_store] = self.class.default_ssl_cert_store
        end
      end

      @log = args[:log]
      @max_redirects = args[:max_redirects] || 10
      @processed_headers = make_headers headers
      @processed_headers_lowercase = Hash[@processed_headers.map {|k, v| [k.downcase, v]}]
      @args = args

      @before_execution_proc = args[:before_execution_proc]
    end

    def execute & block
      # With 2.0.0+, net/http accepts URI objects in requests and handles wrapping
      # IPv6 addresses in [] for use in the Host request header.
      transmit uri, net_http_request_class(method).new(uri, processed_headers), payload, & block
    ensure
      payload.close if payload
    end

    # SSL-related options
    def verify_ssl
      @ssl_opts.fetch(:verify_ssl)
    end
    SSLOptionList.each do |key|
      define_method('ssl_' + key) do
        @ssl_opts[key.to_sym]
      end
    end

    # Return true if the request URI will use HTTPS.
    #
    # @return [Boolean]
    #
    def use_ssl?
      uri.is_a?(URI::HTTPS)
    end

    # Extract the query parameters and append them to the url
    #
    # Look through the headers hash for a :params option (case-insensitive,
    # may be string or symbol). If present and the value is a Hash or
    # RestClient::ParamsArray, *delete* the key/value pair from the headers
    # hash and encode the value into a query string. Append this query string
    # to the URL and return the resulting URL.
    #
    # @param [String] url
    # @param [Hash] headers An options/headers hash to process. Mutation
    #   warning: the params key may be removed if present!
    #
    # @return [String] resulting url with query string
    #
    def process_url_params(url, headers)
      url_params = nil

      # find and extract/remove "params" key if the value is a Hash/ParamsArray
      headers.delete_if do |key, value|
        if key.to_s.downcase == 'params' &&
            (value.is_a?(Hash) || value.is_a?(RestClient::ParamsArray))
          if url_params
            raise ArgumentError.new("Multiple 'params' options passed")
          end
          url_params = value
          true
        else
          false
        end
      end

      # build resulting URL with query string
      if url_params && !url_params.empty?
        query_string = RestClient::Utils.encode_query_string(url_params)

        if url.include?('?')
          url + '&' + query_string
        else
          url + '?' + query_string
        end
      else
        url
      end
    end

    # Render a hash of key => value pairs for cookies in the Request#cookie_jar
    # that are valid for the Request#uri. This will not necessarily include all
    # cookies if there are duplicate keys. It's safer to use the cookie_jar
    # directly if that's a concern.
    #
    # @see Request#cookie_jar
    #
    # @return [Hash]
    #
    def cookies
      hash = {}

      @cookie_jar.cookies(uri).each do |c|
        hash[c.name] = c.value
      end

      hash
    end

    # @return [HTTP::CookieJar]
    def cookie_jar
      @cookie_jar
    end

    # Render a Cookie HTTP request header from the contents of the @cookie_jar,
    # or nil if the jar is empty.
    #
    # @see Request#cookie_jar
    #
    # @return [String, nil]
    #
    def make_cookie_header
      return nil if cookie_jar.nil?

      arr = cookie_jar.cookies(url)
      return nil if arr.empty?

      return HTTP::Cookie.cookie_value(arr)
    end

    # Process cookies passed as hash or as HTTP::CookieJar. For backwards
    # compatibility, these may be passed as a :cookies option masquerading
    # inside the headers hash. To avoid confusion, if :cookies is passed in
    # both headers and Request#initialize, raise an error.
    #
    # :cookies may be a:
    # - Hash{String/Symbol => String}
    # - Array<HTTP::Cookie>
    # - HTTP::CookieJar
    #
    # Passing as a hash:
    #   Keys may be symbols or strings. Values must be strings.
    #   Infer the domain name from the request URI and allow subdomains (as
    #   though '.example.com' had been set in a Set-Cookie header). Assume a
    #   path of '/'.
    #
    #     RestClient::Request.new(url: 'http://example.com', method: :get,
    #       :cookies => {:foo => 'Value', 'bar' => '123'}
    #     )
    #
    # results in cookies as though set from the server by:
    #     Set-Cookie: foo=Value; Domain=.example.com; Path=/
    #     Set-Cookie: bar=123; Domain=.example.com; Path=/
    #
    # which yields a client cookie header of:
    #     Cookie: foo=Value; bar=123
    #
    # Passing as HTTP::CookieJar, which will be passed through directly:
    #
    #     jar = HTTP::CookieJar.new
    #     jar.add(HTTP::Cookie.new('foo', 'Value', domain: 'example.com',
    #                              path: '/', for_domain: false))
    #
    #     RestClient::Request.new(..., :cookies => jar)
    #
    # @param [URI::HTTP] uri The URI for the request. This will be used to
    # infer the domain name for cookies passed as strings in a hash. To avoid
    # this implicit behavior, pass a full cookie jar or use HTTP::Cookie hash
    # values.
    # @param [Hash] headers The headers hash from which to pull the :cookies
    #   option. MUTATION NOTE: This key will be deleted from the hash if
    #   present.
    # @param [Hash] args The options passed to Request#initialize. This hash
    #   will be used as another potential source for the :cookies key.
    #   These args will not be mutated.
    #
    # @return [HTTP::CookieJar] A cookie jar containing the parsed cookies.
    #
    def process_cookie_args!(uri, headers, args)

      # Avoid ambiguity in whether options from headers or options from
      # Request#initialize should take precedence by raising ArgumentError when
      # both are present. Prior versions of rest-client claimed to give
      # precedence to init options, but actually gave precedence to headers.
      # Avoid that mess by erroring out instead.
      if headers[:cookies] && args[:cookies]
        raise ArgumentError.new(
          "Cannot pass :cookies in Request.new() and in headers hash")
      end

      cookies_data = headers.delete(:cookies) || args[:cookies]

      # return copy of cookie jar as is
      if cookies_data.is_a?(HTTP::CookieJar)
        return cookies_data.dup
      end

      # convert cookies hash into a CookieJar
      jar = HTTP::CookieJar.new

      (cookies_data || []).each do |key, val|

        # Support for Array<HTTP::Cookie> mode:
        # If key is a cookie object, add it to the jar directly and assert that
        # there is no separate val.
        if key.is_a?(HTTP::Cookie)
          if val
            raise ArgumentError.new("extra cookie val: #{val.inspect}")
          end

          jar.add(key)
          next
        end

        if key.is_a?(Symbol)
          key = key.to_s
        end

        # assume implicit domain from the request URI, and set for_domain to
        # permit subdomains
        jar.add(HTTP::Cookie.new(key, val, domain: uri.hostname.downcase,
                                 path: '/', for_domain: true))
      end

      jar
    end

    # Generate headers for use by a request. Header keys will be stringified
    # using `#stringify_headers` to normalize them as capitalized strings.
    #
    # The final headers consist of:
    #   - default headers from #default_headers
    #   - user_headers provided here
    #   - headers from the payload object (e.g. Content-Type, Content-Lenth)
    #   - cookie headers from #make_cookie_header
    #
    # BUG: stringify_headers does not alter the capitalization of headers that
    # are passed as strings, it only normalizes those passed as symbols. This
    # behavior will probably remain for a while for compatibility, but it means
    # that the warnings that attempt to detect accidental header overrides may
    # not always work.
    # https://github.com/rest-client/rest-client/issues/599
    #
    # @param [Hash] user_headers User-provided headers to include
    #
    # @return [Hash<String, String>] A hash of HTTP headers => values
    #
    def make_headers(user_headers)
      headers = stringify_headers(default_headers).merge(stringify_headers(user_headers))

      # override headers from the payload (e.g. Content-Type, Content-Length)
      if @payload
        payload_headers = @payload.headers

        # Warn the user if we override any headers that were previously
        # present. This usually indicates that rest-client was passed
        # conflicting information, e.g. if it was asked to render a payload as
        # x-www-form-urlencoded but a Content-Type application/json was
        # also supplied by the user.
        payload_headers.each_pair do |key, val|
          if headers.include?(key) && headers[key] != val
            warn("warning: Overriding #{key.inspect} header " +
                 "#{headers.fetch(key).inspect} with #{val.inspect} " +
                 "due to payload")
          end
        end

        headers.merge!(payload_headers)
      end

      # merge in cookies
      cookies = make_cookie_header
      if cookies && !cookies.empty?
        if headers['Cookie']
          warn('warning: overriding "Cookie" header with :cookies option')
        end
        headers['Cookie'] = cookies
      end

      headers
    end

    # The proxy URI for this request. If `:proxy` was provided on this request,
    # use it over `RestClient.proxy`.
    #
    # Return false if a proxy was explicitly set and is falsy.
    #
    # @return [URI, false, nil]
    #
    def proxy_uri
      if defined?(@proxy)
        if @proxy
          URI.parse(@proxy)
        else
          false
        end
      elsif RestClient.proxy_set?
        if RestClient.proxy
          URI.parse(RestClient.proxy)
        else
          false
        end
      else
        nil
      end
    end

    def net_http_object(hostname, port)
      p_uri = proxy_uri

      if p_uri.nil?
        # no proxy set
        Net::HTTP.new(hostname, port)
      elsif !p_uri
        # proxy explicitly set to none
        Net::HTTP.new(hostname, port, nil, nil, nil, nil)
      else
        Net::HTTP.new(hostname, port,
                      p_uri.hostname, p_uri.port, p_uri.user, p_uri.password)

      end
    end

    def net_http_request_class(method)
      Net::HTTP.const_get(method.capitalize, false)
    end

    def net_http_do_request(http, req, body=nil, &block)
      if body && body.respond_to?(:read)
        req.body_stream = body
        return http.request(req, nil, &block)
      else
        return http.request(req, body, &block)
      end
    end

    # Normalize a URL by adding a protocol if none is present.
    #
    # If the string has no HTTP-like scheme (i.e. scheme followed by '//'), a
    # scheme of 'http' will be added. This mimics the behavior of browsers and
    # user agents like cURL.
    #
    # @param [String] url A URL string.
    #
    # @return [String]
    #
    def normalize_url(url)
      url = 'http://' + url unless url.match(%r{\A[a-z][a-z0-9+.-]*://}i)
      url
    end

    # Return a certificate store that can be used to validate certificates with
    # the system certificate authorities. This will probably not do anything on
    # OS X, which monkey patches OpenSSL in terrible ways to insert its own
    # validation. On most *nix platforms, this will add the system certifcates
    # using OpenSSL::X509::Store#set_default_paths. On Windows, this will use
    # RestClient::Windows::RootCerts to look up the CAs trusted by the system.
    #
    # @return [OpenSSL::X509::Store]
    #
    def self.default_ssl_cert_store
      cert_store = OpenSSL::X509::Store.new
      cert_store.set_default_paths

      # set_default_paths() doesn't do anything on Windows, so look up
      # certificates using the win32 API.
      if RestClient::Platform.windows?
        RestClient::Windows::RootCerts.instance.to_a.uniq.each do |cert|
          begin
            cert_store.add_cert(cert)
          rescue OpenSSL::X509::StoreError => err
            # ignore duplicate certs
            raise unless err.message == 'cert already in hash table'
          end
        end
      end

      cert_store
    end

    def redacted_uri
      if uri.password
        sanitized_uri = uri.dup
        sanitized_uri.password = 'REDACTED'
        sanitized_uri
      else
        uri
      end
    end

    def redacted_url
      redacted_uri.to_s
    end

    # Default to the global logger if there's not a request-specific one
    def log
      @log || RestClient.log
    end

    def log_request
      return unless log

      out = []

      out << "RestClient.#{method} #{redacted_url.inspect}"
      out << payload.short_inspect if payload
      out << processed_headers.to_a.sort.map { |(k, v)| [k.inspect, v.inspect].join("=>") }.join(", ")
      log << out.join(', ') + "\n"
    end

    # Return a hash of headers whose keys are capitalized strings
    #
    # BUG: stringify_headers does not fix the capitalization of headers that
    # are already Strings. Leaving this behavior as is for now for
    # backwards compatibility.
    # https://github.com/rest-client/rest-client/issues/599
    #
    def stringify_headers headers
      headers.inject({}) do |result, (key, value)|
        if key.is_a? Symbol
          key = key.to_s.split(/_/).map(&:capitalize).join('-')
        end
        if 'CONTENT-TYPE' == key.upcase
          result[key] = maybe_convert_extension(value.to_s)
        elsif 'ACCEPT' == key.upcase
          # Accept can be composed of several comma-separated values
          if value.is_a? Array
            target_values = value
          else
            target_values = value.to_s.split ','
          end
          result[key] = target_values.map { |ext|
            maybe_convert_extension(ext.to_s.strip)
          }.join(', ')
        else
          result[key] = value.to_s
        end
        result
      end
    end

    # Default headers set by RestClient. In addition to these headers, servers
    # will receive headers set by Net::HTTP, such as Accept-Encoding and Host.
    #
    # @return [Hash<Symbol, String>]
    def default_headers
      {
        :accept => '*/*',
        :user_agent => RestClient::Platform.default_user_agent,
      }
    end

    private

    # Parse the `@url` string into a URI object and save it as
    # `@uri`. Also save any basic auth user or password as @user and @password.
    # If no auth info was passed, check for credentials in a Netrc file.
    #
    # @param [String] url A URL string.
    #
    # @return [URI]
    #
    # @raise URI::InvalidURIError on invalid URIs
    #
    def parse_url_with_auth!(url)
      uri = URI.parse(url)

      if uri.hostname.nil?
        raise URI::InvalidURIError.new("bad URI(no host provided): #{url}")
      end

      @user = CGI.unescape(uri.user) if uri.user
      @password = CGI.unescape(uri.password) if uri.password
      if !@user && !@password
        @user, @password = Netrc.read[uri.hostname]
      end

      @uri = uri
    end

    def print_verify_callback_warnings
      warned = false
      if RestClient::Platform.mac_mri?
        warn('warning: ssl_verify_callback return code is ignored on OS X')
        warned = true
      end
      if RestClient::Platform.jruby?
        warn('warning: SSL verify_callback may not work correctly in jruby')
        warn('see https://github.com/jruby/jruby/issues/597')
        warned = true
      end
      warned
    end

    # Parse a method and return a normalized string version.
    #
    # Raise ArgumentError if the method is falsy, but otherwise do no
    # validation.
    #
    # @param method [String, Symbol]
    #
    # @return [String]
    #
    # @see net_http_request_class
    #
    def normalize_method(method)
      raise ArgumentError.new('must pass :method') unless method
      method.to_s.downcase
    end

    def transmit uri, req, payload, & block

      # We set this to true in the net/http block so that we can distinguish
      # read_timeout from open_timeout. Now that we only support Ruby 2.0+,
      # this is only needed for Timeout exceptions thrown outside of Net::HTTP.
      established_connection = false

      setup_credentials req

      net = net_http_object(uri.hostname, uri.port)
      net.use_ssl = uri.is_a?(URI::HTTPS)
      net.ssl_version = ssl_version if ssl_version
      net.ciphers = ssl_ciphers if ssl_ciphers

      net.verify_mode = verify_ssl

      net.cert = ssl_client_cert if ssl_client_cert
      net.key = ssl_client_key if ssl_client_key
      net.ca_file = ssl_ca_file if ssl_ca_file
      net.ca_path = ssl_ca_path if ssl_ca_path
      net.cert_store = ssl_cert_store if ssl_cert_store

      # We no longer rely on net.verify_callback for the main SSL verification
      # because it's not well supported on all platforms (see comments below).
      # But do allow users to set one if they want.
      if ssl_verify_callback
        net.verify_callback = ssl_verify_callback

        # Hilariously, jruby only calls the callback when cert_store is set to
        # something, so make sure to set one.
        # https://github.com/jruby/jruby/issues/597
        if RestClient::Platform.jruby?
          net.cert_store ||= OpenSSL::X509::Store.new
        end

        if ssl_verify_callback_warnings != false
          if print_verify_callback_warnings
            warn('pass :ssl_verify_callback_warnings => false to silence this')
          end
        end
      end

      if OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE
        warn('WARNING: OpenSSL::SSL::VERIFY_PEER == OpenSSL::SSL::VERIFY_NONE')
        warn('This dangerous monkey patch leaves you open to MITM attacks!')
        warn('Try passing :verify_ssl => false instead.')
      end

      if defined? @read_timeout
        if @read_timeout == -1
          warn 'Deprecated: to disable timeouts, please use nil instead of -1'
          @read_timeout = nil
        end
        net.read_timeout = @read_timeout
      end
      if defined? @open_timeout
        if @open_timeout == -1
          warn 'Deprecated: to disable timeouts, please use nil instead of -1'
          @open_timeout = nil
        end
        net.open_timeout = @open_timeout
      end

      RestClient.before_execution_procs.each do |before_proc|
        before_proc.call(req, args)
      end

      if @before_execution_proc
        @before_execution_proc.call(req, args)
      end

      log_request

      start_time = Time.now
      tempfile = nil

      net.start do |http|
        established_connection = true

        if @block_response
          net_http_do_request(http, req, payload, &@block_response)
        else
          res = net_http_do_request(http, req, payload) { |http_response|
            if @raw_response
              # fetch body into tempfile
              tempfile = fetch_body_to_tempfile(http_response)
            else
              # fetch body
              http_response.read_body
            end
            http_response
          }
          process_result(res, start_time, tempfile, &block)
        end
      end
    rescue EOFError
      raise RestClient::ServerBrokeConnection
    rescue Net::OpenTimeout => err
      raise RestClient::Exceptions::OpenTimeout.new(nil, err)
    rescue Net::ReadTimeout => err
      raise RestClient::Exceptions::ReadTimeout.new(nil, err)
    rescue Timeout::Error, Errno::ETIMEDOUT => err
      # handling for non-Net::HTTP timeouts
      if established_connection
        raise RestClient::Exceptions::ReadTimeout.new(nil, err)
      else
        raise RestClient::Exceptions::OpenTimeout.new(nil, err)
      end

    rescue OpenSSL::SSL::SSLError => error
      # TODO: deprecate and remove RestClient::SSLCertificateNotVerified and just
      # pass through OpenSSL::SSL::SSLError directly.
      #
      # Exceptions in verify_callback are ignored [1], and jruby doesn't support
      # it at all [2]. RestClient has to catch OpenSSL::SSL::SSLError and either
      # re-throw it as is, or throw SSLCertificateNotVerified based on the
      # contents of the message field of the original exception.
      #
      # The client has to handle OpenSSL::SSL::SSLError exceptions anyway, so
      # we shouldn't make them handle both OpenSSL and RestClient exceptions.
      #
      # [1] https://github.com/ruby/ruby/blob/89e70fe8e7/ext/openssl/ossl.c#L238
      # [2] https://github.com/jruby/jruby/issues/597

      if error.message.include?("certificate verify failed")
        raise SSLCertificateNotVerified.new(error.message)
      else
        raise error
      end
    end

    def setup_credentials(req)
      if user && !@processed_headers_lowercase.include?('authorization')
        req.basic_auth(user, password)
      end
    end

    def fetch_body_to_tempfile(http_response)
      # Taken from Chef, which as in turn...
      # Stolen from http://www.ruby-forum.com/topic/166423
      # Kudos to _why!
      tf = Tempfile.new('rest-client.')
      tf.binmode

      size = 0
      total = http_response['Content-Length'].to_i
      stream_log_bucket = nil

      http_response.read_body do |chunk|
        tf.write chunk
        size += chunk.size
        if log
          if total == 0
            log << "streaming %s %s (%d of unknown) [0 Content-Length]\n" % [@method.upcase, @url, size]
          else
            percent = (size * 100) / total
            current_log_bucket, _ = percent.divmod(@stream_log_percent)
            if current_log_bucket != stream_log_bucket
              stream_log_bucket = current_log_bucket
              log << "streaming %s %s %d%% done (%d of %d)\n" % [@method.upcase, @url, (size * 100) / total, size, total]
            end
          end
        end
      end
      tf.close
      tf
    end

    # @param res The Net::HTTP response object
    # @param start_time [Time] Time of request start
    def process_result(res, start_time, tempfile=nil, &block)
      if @raw_response
        unless tempfile
          raise ArgumentError.new('tempfile is required')
        end
        response = RawResponse.new(tempfile, res, self, start_time)
      else
        response = Response.create(res.body, res, self, start_time)
      end

      response.log_response

      if block_given?
        block.call(response, self, res, & block)
      else
        response.return!(&block)
      end

    end

    def parser
      URI.const_defined?(:Parser) ? URI::Parser.new : URI
    end

    # Given a MIME type or file extension, return either a MIME type or, if
    # none is found, the input unchanged.
    #
    #     >> maybe_convert_extension('json')
    #     => 'application/json'
    #
    #     >> maybe_convert_extension('unknown')
    #     => 'unknown'
    #
    #     >> maybe_convert_extension('application/xml')
    #     => 'application/xml'
    #
    # @param ext [String]
    #
    # @return [String]
    #
    def maybe_convert_extension(ext)
      unless ext =~ /\A[a-zA-Z0-9_@-]+\z/
        # Don't look up strings unless they look like they could be a file
        # extension known to mime-types.
        #
        # There currently isn't any API public way to look up extensions
        # directly out of MIME::Types, but the type_for() method only strips
        # off after a period anyway.
        return ext
      end

      types = MIME::Types.type_for(ext)
      if types.empty?
        ext
      else
        types.first.content_type
      end
    end
  end
end
