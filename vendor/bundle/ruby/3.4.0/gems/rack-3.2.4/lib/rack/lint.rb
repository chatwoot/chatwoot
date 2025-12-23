# frozen_string_literal: true

require 'forwardable'

require_relative 'constants'
require_relative 'utils'

module Rack
  # Validates your application and the requests and responses according to the Rack spec. See SPEC.rdoc for details.
  class Lint
    # Represents a failure to meet the Rack specification.
    class LintError < RuntimeError; end

    # Invoke the application, validating the request and response according to the Rack spec.
    def call(env = nil)
      Wrapper.new(@app, env).response
    end

    # :stopdoc:

    ALLOWED_SCHEMES = %w(https http wss ws).freeze

    REQUEST_PATH_ORIGIN_FORM = /\A\/[^#]*\z/
    REQUEST_PATH_ABSOLUTE_FORM = /\A#{Utils::URI_PARSER.make_regexp}\z/
    REQUEST_PATH_AUTHORITY_FORM = /\A[^\/:]+:\d+\z/
    REQUEST_PATH_ASTERISK_FORM = '*'

    # Match a host name, according to RFC3986. Copied from `URI::RFC3986_Parser::HOST` because older Ruby versions (< 3.3) don't expose it.
    HOST_PATTERN = /
      (?<IP-literal>\[(?:
          (?<IPv6address>
            (?:\h{1,4}:){6}
            (?<ls32>\h{1,4}:\h{1,4}
            | (?<IPv4address>(?<dec-octet>[1-9]\d|1\d{2}|2[0-4]\d|25[0-5]|\d)
                \.\g<dec-octet>\.\g<dec-octet>\.\g<dec-octet>)
            )
          | ::(?:\h{1,4}:){5}\g<ls32>
          | \h{1,4}?::(?:\h{1,4}:){4}\g<ls32>
          | (?:(?:\h{1,4}:)?\h{1,4})?::(?:\h{1,4}:){3}\g<ls32>
          | (?:(?:\h{1,4}:){,2}\h{1,4})?::(?:\h{1,4}:){2}\g<ls32>
          | (?:(?:\h{1,4}:){,3}\h{1,4})?::\h{1,4}:\g<ls32>
          | (?:(?:\h{1,4}:){,4}\h{1,4})?::\g<ls32>
          | (?:(?:\h{1,4}:){,5}\h{1,4})?::\h{1,4}
          | (?:(?:\h{1,4}:){,6}\h{1,4})?::
          )
        | (?<IPvFuture>v\h++\.[!$&-.0-9:;=A-Z_a-z~]++)
        )\])
    | \g<IPv4address>
    | (?<reg-name>(?:%\h\h|[!$&-.0-9;=A-Z_a-z~])*+)
    /x.freeze
    SERVER_NAME_PATTERN = /\A#{HOST_PATTERN}\z/.freeze
    HTTP_HOST_PATTERN = /\A#{HOST_PATTERN}(:\d*+)?\z/.freeze

    private_constant :HOST_PATTERN, :SERVER_NAME_PATTERN, :HTTP_HOST_PATTERN

    # N.B. The empty `##` comments creates paragraphs in the output. A trailing "\" is used to escape the newline character, which combines the comments into a single paragraph.
    #
    ## = Rack Specification
    ##
    ## This specification aims to formalize the Rack protocol. You can (and should) use +Rack::Lint+ to enforce it. When you develop middleware, be sure to test with +Rack::Lint+ to catch possible violations of this specification.
    ##
    ## == The Application
    ##
    ## A Rack application is a Ruby object that responds to +call+. \
    def initialize(app)
      raise LintError, "app must respond to call" unless app.respond_to?(:call)

      @app = app
    end

    class Wrapper
      def initialize(app, env)
        @app = app
        @env = env
        @response = nil
        @head_request = false

        @status = nil
        @headers = nil
        @body = nil
        @consumed = nil
        @content_length = nil
        @closed = false
        @size = 0
      end

      def response
        ## It takes exactly one argument, the +environment+ (representing an HTTP request) \
        raise LintError, "No env given" unless @env
        check_environment(@env)

        ## and returns a non-frozen +Array+ of exactly three elements: \
        @response = @app.call(@env)

        raise LintError, "response is not an Array, but #{@response.class}" unless @response.kind_of? Array
        raise LintError, "response is frozen" if @response.frozen?
        raise LintError, "response array has #{@response.size} elements instead of 3" unless @response.size == 3

        @status, @headers, @body = @response
        ## the +status+, \
        check_status(@status)

        ## the +headers+, \
        check_headers(@headers)

        hijack_proc = check_hijack_response(@headers, @env)
        if hijack_proc
          @headers[RACK_HIJACK] = hijack_proc
        end

        ## and the +body+ (representing an HTTP response).
        check_content_type_header(@status, @headers)
        check_content_length_header(@status, @headers)
        check_rack_protocol_header(@status, @headers)
        @head_request = @env[REQUEST_METHOD] == HEAD

        @lint = (@env['rack.lint'] ||= []) << self

        if (@env['rack.lint.body_iteration'] ||= 0) > 0
          raise LintError, "Middleware must not call #each directly"
        end

        return [@status, @headers, self]
      end

      private def assert_required(key)
        raise LintError, "env missing required key #{key}" unless @env.include?(key)

        return @env[key]
      end

      ##
      ## == The Request Environment
      ##
      ## Incoming HTTP requests are represented using an environment. \
      def check_environment(env)
        ## The environment must be an unfrozen +Hash+. The Rack application is free to modify the environment, but the modified environment should also comply with this specification. \
        raise LintError, "env #{env.inspect} is not a Hash, but #{env.class}" unless env.kind_of? Hash
        raise LintError, "env should not be frozen, but is" if env.frozen?

        ## All environment keys must be strings.
        keys = env.keys
        keys.reject!{|key| String === key}
        unless keys.empty?
          raise LintError, "env contains non-string keys: #{keys.inspect}"
        end

        ##
        ## === CGI Variables
        ##
        ## The environment is required to include these variables, adopted from {The Common Gateway Interface}[https://datatracker.ietf.org/doc/html/rfc3875] (CGI), except when they'd be empty, but see below.

        ##
        ## The CGI keys (named without a period) must have +String+ values and are reserved for the Rack specification. If the values for CGI keys contain non-ASCII characters, they should use <tt>ASCII-8BIT</tt> encoding.
        env.each do |key, value|
          next if key.include?(".") # Skip extensions
          
          unless value.kind_of? String
            raise LintError, "env variable #{key} has non-string value #{value.inspect}"
          end

          next if value.encoding == Encoding::ASCII_8BIT

          unless value.b !~ /[\x80-\xff]/n
            raise LintError, "env variable #{key} has value containing non-ASCII characters and has non-ASCII-8BIT encoding #{value.inspect} encoding: #{value.encoding}"
          end
        end

        ##
        ## The server and application can store their own data in the environment, too. The keys must contain at least one dot, and should be prefixed uniquely. The prefix <tt>rack.</tt> is reserved for use with the Rack specification and the classes that ship with Rack.

        ##
        ## ==== <tt>REQUEST_METHOD</tt>
        ##
        ## The HTTP request method, such as "GET" or "POST". This cannot ever be an empty string, and so is always required.
        request_method = assert_required(REQUEST_METHOD)
        unless request_method =~ /\A[0-9A-Za-z!\#$%&'*+.^_`|~-]+\z/
          raise LintError, "REQUEST_METHOD unknown: #{request_method.inspect}"
        end

        ##
        ## ==== <tt>SCRIPT_NAME</tt>
        ##
        ## The initial portion of the request URL's path that corresponds to the application object, so that the application knows its virtual location. This may be an empty string, if the application corresponds to the root of the server. If non-empty, the string must start with <tt>/</tt>, but should not end with <tt>/</tt>.
        if script_name = env[SCRIPT_NAME]
          if script_name != "" && script_name !~ /\A\//
            raise LintError, "SCRIPT_NAME must start with /"
          end

          ##
          ## In addition, <tt>SCRIPT_NAME</tt> MUST not be <tt>/</tt>, but instead be empty, \
          if script_name == "/"
            raise LintError, "SCRIPT_NAME cannot be '/', make it '' and PATH_INFO '/'"
          end
        end

        ## and one of <tt>SCRIPT_NAME</tt> or <tt>PATH_INFO</tt> must be set, e.g. <tt>PATH_INFO</tt> can be <tt>/</tt> if <tt>SCRIPT_NAME</tt> is empty.
        path_info = env[PATH_INFO]
        if (script_name.nil? || script_name.empty?) && (path_info.nil? || path_info.empty?)
          raise LintError, "One of SCRIPT_NAME or PATH_INFO must be set (make PATH_INFO '/' if SCRIPT_NAME is empty)"
        end

        ##
        ## ==== <tt>PATH_INFO</tt>
        ##
        ## The remainder of the request URL's "path", designating the virtual "location" of the request's target within the application. This may be an empty string, if the request URL targets the application root and does not have a trailing slash. This value may be percent-encoded when originating from a URL.
        ##
        ## The <tt>PATH_INFO</tt>, if provided, must be a valid request target or an empty string, as defined by {RFC9110}[https://datatracker.ietf.org/doc/html/rfc9110#target.resource].
        case path_info
        when REQUEST_PATH_ASTERISK_FORM
          ## * Only <tt>OPTIONS</tt> requests may have <tt>PATH_INFO</tt> set to <tt>*</tt> (asterisk-form).
          unless request_method == OPTIONS
            raise LintError, "Only OPTIONS requests may have PATH_INFO set to '*' (asterisk-form)"
          end
        when REQUEST_PATH_AUTHORITY_FORM
          ## * Only <tt>CONNECT</tt> requests may have <tt>PATH_INFO</tt> set to an authority (authority-form). Note that in HTTP/2+, the authority-form is not a valid request target.
          unless request_method == CONNECT
            raise LintError, "Only CONNECT requests may have PATH_INFO set to an authority (authority-form)"
          end
        when REQUEST_PATH_ABSOLUTE_FORM
          ## * <tt>CONNECT</tt> and <tt>OPTIONS</tt> requests must not have <tt>PATH_INFO</tt> set to a URI (absolute-form).
          if request_method == CONNECT || request_method == OPTIONS
            raise LintError, "CONNECT and OPTIONS requests must not have PATH_INFO set to a URI (absolute-form)"
          end
        when REQUEST_PATH_ORIGIN_FORM
          ## * Otherwise, <tt>PATH_INFO</tt> must start with a <tt>/</tt> and must not include a fragment part starting with <tt>#</tt> (origin-form).
        when "", nil
          # Empty string or nil is okay.
        else
          raise LintError, "PATH_INFO must start with a '/' and must not include a fragment part starting with '#' (origin-form)"
        end

        ##
        ## ==== <tt>QUERY_STRING</tt>
        ##
        ## The portion of the request URL that follows the <tt>?</tt>, if any. May be empty, but is always required!
        assert_required(QUERY_STRING)

        ##
        ## ==== <tt>SERVER_NAME</tt>
        ##
        ## Must be a valid host, as defined by {RFC3986}[https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2].
        ##
        ## When combined with <tt>SCRIPT_NAME</tt>, <tt>PATH_INFO</tt>, and <tt>QUERY_STRING</tt>, these variables can be used to reconstruct the original the request URL. Note, however, that <tt>HTTP_HOST</tt>, if present, should be used in preference to <tt>SERVER_NAME</tt> for reconstructing the request URL.
        server_name = assert_required(SERVER_NAME)
        unless server_name.match?(SERVER_NAME_PATTERN)
          raise LintError, "env[SERVER_NAME] must be a valid host"
        end

        ##
        ## ==== <tt>SERVER_PROTOCOL</tt>
        ##
        ## The HTTP version used for the request. It must match the regular expression <tt>HTTP\/\d(\.\d)?</tt>.
        server_protocol = assert_required(SERVER_PROTOCOL)
        unless %r{HTTP/\d(\.\d)?}.match?(server_protocol)
          raise LintError, "env[SERVER_PROTOCOL] does not match HTTP/\\d(\\.\\d)?"
        end

        ##
        ## ==== <tt>SERVER_PORT</tt>
        ##
        ## The port the server is running on, if the server is running on a non-standard port. It must consist of digits only.
        ##
        ## The standard ports are:
        ## * 80 for HTTP
        ## * 443 for HTTPS
        if server_port = env[SERVER_PORT]
          unless server_port =~ /\A\d+\z/
            raise LintError, "env[SERVER_PORT] is not an Integer"
          end
        end

        ##
        ## ==== <tt>CONTENT_TYPE</tt>
        ##
        ## The optional MIME type of the request body, if any.
        # N.B. We do not validate this field as it is considered user-provided data.

        ##
        ## ==== <tt>CONTENT_LENGTH</tt>
        ##
        ## The length of the request body, if any. It must consist of digits only.
        if content_length = env["CONTENT_LENGTH"]
          if content_length !~ /\A\d+\z/
            raise LintError, "Invalid CONTENT_LENGTH: #{content_length.inspect}"
          end
        end

        ##
        ## ==== <tt>HTTP_HOST</tt>
        ##
        ## An optional HTTP authority, as defined by {RFC9110}[https://datatracker.ietf.org/doc/html/rfc9110#name-host-and-authority].
        if http_host = env[HTTP_HOST]
          unless http_host.match?(HTTP_HOST_PATTERN)
            raise LintError, "env[HTTP_HOST] must be a valid authority"
          end
        end

        ##
        ## ==== <tt>HTTP_</tt> Headers
        ##
        ## Unless specified above, the environment can contain any number of additional headers, each starting with <tt>HTTP_</tt>. The presence or absence of these variables should correspond with the presence or absence of the appropriate HTTP header in the request, and those headers have no specific interpretation or validation by the Rack specification. However, there are many standard HTTP headers that have a specific meaning in the context of a request; see {RFC3875 section 4.1.18}[https://tools.ietf.org/html/rfc3875#section-4.1.18] for more details.
        ##
        ## For compatibility with the CGI specifiction, the environment must not contain the keys <tt>HTTP_CONTENT_TYPE</tt> or <tt>HTTP_CONTENT_LENGTH</tt>. Instead, the keys <tt>CONTENT_TYPE</tt> and <tt>CONTENT_LENGTH</tt> must be used.
        %w[HTTP_CONTENT_TYPE HTTP_CONTENT_LENGTH].each do |header|
          if env.include?(header)
            raise LintError, "env contains #{header}, must use #{header[5..-1]}"
          end
        end

        ##
        ## === Rack-Specific Variables
        ##
        ## In addition to CGI variables, the Rack environment includes Rack-specific variables. These variables are prefixed with <tt>rack.</tt> and are reserved for use by the Rack specification, or by the classes that ship with Rack.
        ##
        ## ==== <tt>rack.url_scheme</tt>
        ##
        ## The URL scheme, which must be one of <tt>http</tt>, <tt>https</tt>, <tt>ws</tt> or <tt>wss</tt>. This can never be an empty string, and so is always required. The scheme should be set according to the last hop. For example, if a client makes a request to a reverse proxy over HTTPS, but the connection between the reverse proxy and the server is over plain HTTP, the reverse proxy should set <tt>rack.url_scheme</tt> to <tt>http</tt>.
        rack_url_scheme = assert_required(RACK_URL_SCHEME)
        unless ALLOWED_SCHEMES.include?(rack_url_scheme)
          raise LintError, "rack.url_scheme unknown: #{rack_url_scheme.inspect}"
        end

        ##
        ## ==== <tt>rack.protocol</tt>
        ##
        ## An optional +Array+ of +String+ values, containing the protocols advertised by the client in the <tt>upgrade</tt> header (HTTP/1) or the <tt>:protocol</tt> pseudo-header (HTTP/2+).
        if protocols = env[RACK_PROTOCOL]
          unless protocols.is_a?(Array) && protocols.all?{|protocol| protocol.is_a?(String)}
            raise LintError, "rack.protocol must be an Array of Strings"
          end
        end

        ##
        ## ==== <tt>rack.session</tt>
        ##
        ## An optional +Hash+-like interface for storing request session data. The store must implement:
        if session = env[RACK_SESSION]
          ## * <tt>store(key, value)</tt> (aliased as <tt>[]=</tt>) to set a value for a key,
          unless session.respond_to?(:store) && session.respond_to?(:[]=)
            raise LintError, "session #{session.inspect} must respond to store and []="
          end

          ## * <tt>fetch(key, default = nil)</tt> (aliased as <tt>[]</tt>) to retrieve a value for a key,
          unless session.respond_to?(:fetch) && session.respond_to?(:[])
            raise LintError, "session #{session.inspect} must respond to fetch and []"
          end

          ## * <tt>delete(key)</tt> to delete a key,
          unless session.respond_to?(:delete)
            raise LintError, "session #{session.inspect} must respond to delete"
          end

          ## * <tt>clear</tt> to clear the session,
          unless session.respond_to?(:clear)
            raise LintError, "session #{session.inspect} must respond to clear"
          end

          ## * <tt>to_hash</tt> (optional) to retrieve the session as a Hash.
          unless session.respond_to?(:to_hash) && session.to_hash.kind_of?(Hash) && !session.to_hash.frozen?
            raise LintError, "session #{session.inspect} must respond to to_hash and return unfrozen Hash instance"
          end
        end

        ##
        ## ==== <tt>rack.logger</tt>
        ##
        ## An optional +Logger+-like interface for logging messages. The logger must implement:
        if logger = env[RACK_LOGGER]
          ## * <tt>info(message, &block)</tt>,
          unless logger.respond_to?(:info)
            raise LintError, "logger #{logger.inspect} must respond to info"
          end

          ## * <tt>debug(message, &block)</tt>,
          unless logger.respond_to?(:debug)
            raise LintError, "logger #{logger.inspect} must respond to debug"
          end

          ## * <tt>warn(message, &block)</tt>,
          unless logger.respond_to?(:warn)
            raise LintError, "logger #{logger.inspect} must respond to warn"
          end

          ## * <tt>error(message, &block)</tt>,
          unless logger.respond_to?(:error)
            raise LintError, "logger #{logger.inspect} must respond to error"
          end

          ## * <tt>fatal(message, &block)</tt>.
          unless logger.respond_to?(:fatal)
            raise LintError, "logger #{logger.inspect} must respond to fatal"
          end
        end

        ##
        ## ==== <tt>rack.multipart.buffer_size</tt>
        ##
        ## An optional +Integer+ hint to the multipart parser as to what chunk size to use for reads and writes.
        if rack_multipart_buffer_size = env[RACK_MULTIPART_BUFFER_SIZE]
          unless rack_multipart_buffer_size.is_a?(Integer) && rack_multipart_buffer_size > 0
            raise LintError, "rack.multipart.buffer_size must be an Integer > 0 if specified"
          end
        end

        ##
        ## ==== <tt>rack.multipart.tempfile_factory</tt>
        ##
        ## An optional object for constructing temporary files for multipart form data. The factory must implement:
        if rack_multipart_tempfile_factory = env[RACK_MULTIPART_TEMPFILE_FACTORY]
          ## * <tt>call(filename, content_type)</tt> to create a temporary file for a multipart form field.
          unless rack_multipart_tempfile_factory.respond_to?(:call)
            raise LintError, "rack.multipart.tempfile_factory must respond to #call"
          end

          ## The factory must return an +IO+-like object that responds to <tt><<</tt> and optionally <tt>rewind</tt>.
          env[RACK_MULTIPART_TEMPFILE_FACTORY] = lambda do |filename, content_type|
            io = rack_multipart_tempfile_factory.call(filename, content_type)
            unless io.respond_to?(:<<)
              raise LintError, "rack.multipart.tempfile_factory return value must respond to #<<"
            end
            io
          end
        end

        ##
        ## ==== <tt>rack.hijack?</tt>
        ##
        ## If present and truthy, indicates that the server supports partial hijacking. See the section below on hijacking for more information.
        #
        # N.B. There is no specific validation here. If the user provides a partial hijack response, we will confirm this value is truthy in `check_hijack_response`.

        ##
        ## ==== <tt>rack.hijack</tt>
        ##
        ## If present, an object responding to +call+ that is used to perform a full hijack. See the section below on hijacking for more information.
        check_hijack(env)

        ##
        ## ==== <tt>rack.early_hints</tt>
        ##
        ## If present, an object responding to +call+ that is used to send early hints. See the section below on early hints for more information.
        check_early_hints env

        ##
        ## ==== <tt>rack.input</tt>
        ##
        ## If present, the input stream. See the section below on the input stream for more information.
        if rack_input = env[RACK_INPUT]
          check_input_stream(rack_input)
          @env[RACK_INPUT] = InputWrapper.new(rack_input)
        end

        ##
        ## ==== <tt>rack.errors</tt>
        ##
        ## The error stream. See the section below on the error stream for more information.
        rack_errors = assert_required(RACK_ERRORS)
        check_error_stream(rack_errors)
        @env[RACK_ERRORS] = ErrorWrapper.new(rack_errors)

        ##
        ## ==== <tt>rack.response_finished</tt>
        ##
        ## If present, an array of callables that will be run by the server after the response has been processed. The callables are called with <tt>environment, status, headers, error</tt> arguments and should not raise any exceptions. The callables would typically be called after sending the response to the client, but it could also be called if an error occurs while generating the response or sending the response (in that case, the +error+ argument will be a kind of +Exception+). The callables will be called in reverse order.
        if rack_response_finished = env[RACK_RESPONSE_FINISHED]
          raise LintError, "rack.response_finished must be an array of callable objects" unless rack_response_finished.is_a?(Array)
          rack_response_finished.each do |callable|
            raise LintError, "rack.response_finished values must respond to call(env, status, headers, error)" unless callable.respond_to?(:call)
          end
        end
      end

      ##
      ## === The Input Stream
      ##
      ## The input stream is an +IO+-like object which contains the raw HTTP request data. \
      def check_input_stream(input)
        ## When applicable, its external encoding must be <tt>ASCII-8BIT</tt> and it must be opened in binary mode. \
        if input.respond_to?(:external_encoding) && input.external_encoding != Encoding::ASCII_8BIT
          raise LintError, "rack.input #{input} does not have ASCII-8BIT as its external encoding"
        end
        if input.respond_to?(:binmode?) && !input.binmode?
          raise LintError, "rack.input #{input} is not opened in binary mode"
        end

        ## The input stream must respond to +gets+, +each+, and +read+:
        [:gets, :each, :read].each do |method|
          unless input.respond_to? method
            raise LintError, "rack.input #{input} does not respond to ##{method}"
          end
        end
      end

      class InputWrapper
        def initialize(input)
          @input = input
        end

        ## * +gets+ must be called without arguments and return a +String+, or +nil+ on EOF (end-of-file).
        def gets(*args)
          raise LintError, "rack.input#gets called with arguments" unless args.size == 0

          chunk = @input.gets

          unless chunk.nil? or chunk.kind_of? String
            raise LintError, "rack.input#gets didn't return a String"
          end

          chunk
        end

        ## * +read+ behaves like <tt>IO#read</tt>. Its signature is <tt>read([length, [buffer]])</tt>.
        ##   * If given, +length+ must be a non-negative Integer (>= 0) or +nil+, and +buffer+ must be a +String+ and may not be +nil+.
        ##   * If +length+ is given and not +nil+, then this method reads at most +length+ bytes from the input stream.
        ##   * If +length+ is not given or +nil+, then this method reads all data until EOF.
        ##   * When EOF is reached, this method returns +nil+ if +length+ is given and not +nil+, or +""+ if +length+ is not given or is +nil+.
        ##   * If +buffer+ is given, then the read data will be placed into +buffer+ instead of a newly created +String+.
        def read(*args)
          unless args.size <= 2
            raise LintError, "rack.input#read called with too many arguments"
          end
          if args.size >= 1
            unless args.first.kind_of?(Integer) || args.first.nil?
              raise LintError, "rack.input#read called with non-integer and non-nil length"
            end
            unless args.first.nil? || args.first >= 0
              raise LintError, "rack.input#read called with a negative length"
            end
          end
          if args.size >= 2
            unless args[1].kind_of?(String)
              raise LintError, "rack.input#read called with non-String buffer"
            end
          end

          chunk = @input.read(*args)

          unless chunk.nil? or chunk.kind_of? String
            raise LintError, "rack.input#read didn't return nil or a String"
          end
          if args[0].nil?
            unless !chunk.nil?
              raise LintError, "rack.input#read(nil) returned nil on EOF"
            end
          end

          chunk
        end

        ## * +each+ must be called without arguments and only yield +String+ values.
        def each(*args)
          raise LintError, "rack.input#each called with arguments" unless args.size == 0
          @input.each do |line|
            unless line.kind_of? String
              raise LintError, "rack.input#each didn't yield a String"
            end
            yield line
          end
        end

        ## * +close+ can be called on the input stream to indicate that any remaining input is not needed.
        def close(*args)
          @input.close(*args)
        end
      end

      ##
      ## === The Error Stream
      ##
      def check_error_stream(error)
        ## The error stream must respond to +puts+, +write+ and +flush+:
        [:puts, :write, :flush].each do |method|
          unless error.respond_to? method
            raise LintError, "rack.error #{error} does not respond to ##{method}"
          end
        end
      end

      class ErrorWrapper
        def initialize(error)
          @error = error
        end

        ## * +puts+ must be called with a single argument that responds to +to_s+.
        def puts(str)
          @error.puts str
        end

        ## * +write+ must be called with a single argument that is a +String+.
        def write(str)
          raise LintError, "rack.errors#write not called with a String" unless str.kind_of? String
          @error.write str
        end

        ## * +flush+ must be called without arguments and must be called in order to make the error appear for sure.
        def flush
          @error.flush
        end

        ## * +close+ must never be called on the error stream.
        def close(*args)
          raise LintError, "rack.errors#close must not be called"
        end
      end

      ##
      ## === Hijacking
      ##
      ## The hijacking interfaces provides a means for an application to take control of the HTTP connection. There are two distinct hijack interfaces: full hijacking where the application takes over the raw connection, and partial hijacking where the application takes over just the response body stream. In both cases, the application is responsible for closing the hijacked stream.
      ##
      ## Full hijacking only works with HTTP/1. Partial hijacking is functionally equivalent to streaming bodies, and is still optionally supported for backwards compatibility with older Rack versions.
      ##
      ## ==== Full Hijack
      ##
      ## Full hijack is used to completely take over an HTTP/1 connection. It occurs before any headers are written and causes the server to ignore any response generated by the application. It is intended to be used when applications need access to the raw HTTP/1 connection.
      ##
      def check_hijack(env)
        ## If <tt>rack.hijack</tt> is present in +env+, it must respond to +call+ \
        if original_hijack = env[RACK_HIJACK]
          raise LintError, "rack.hijack must respond to call" unless original_hijack.respond_to?(:call)

          env[RACK_HIJACK] = proc do
            io = original_hijack.call

            ## and return an +IO+ object which can be used to read and write to the underlying connection using HTTP/1 semantics and formatting.
            raise LintError, "rack.hijack must return an IO instance" unless io.is_a?(IO)

            io
          end
        end
      end

      ##
      ## ==== Partial Hijack
      ##
      ## Partial hijack is used for bi-directional streaming of the request and response body. It occurs after the status and headers are written by the server and causes the server to ignore the Body of the response. It is intended to be used when applications need bi-directional streaming.
      ##
      def check_hijack_response(headers, env)
        ## If <tt>rack.hijack?</tt> is present in +env+ and truthy, \
        if env[RACK_IS_HIJACK]
          ## an application may set the special response header <tt>rack.hijack</tt> \
          if original_hijack = headers[RACK_HIJACK]
            ## to an object that responds to +call+, \
            unless original_hijack.respond_to?(:call)
              raise LintError, 'rack.hijack header must respond to #call'
            end
            ## accepting a +stream+ argument.
            return proc do |io|
              original_hijack.call StreamWrapper.new(io)
            end
          end
          ##
          ## After the response status and headers have been sent, this hijack callback will be called with a +stream+ argument which follows the same interface as outlined in "Streaming Body". Servers must ignore the +body+ part of the response tuple when the <tt>rack.hijack</tt> response header is present. Using an empty +Array+ is recommended.
        else
          ##
          ## If <tt>rack.hijack?</tt> is not present and truthy, the special response header <tt>rack.hijack</tt> must not be present in the response headers.
          if headers.key?(RACK_HIJACK)
            raise LintError, 'rack.hijack header must not be present if server does not support hijacking'
          end
        end

        nil
      end

      ##
      ## === Early Hints
      ##
      ## The application or any middleware may call the <tt>rack.early_hints</tt> with an object which would be valid as the headers of a Rack response.
      def check_early_hints(env)
        if env[RACK_EARLY_HINTS]
          ##
          ## If <tt>rack.early_hints</tt> is present, it must respond to +call+.
          unless env[RACK_EARLY_HINTS].respond_to?(:call)
            raise LintError, "rack.early_hints must respond to call"
          end

          original_callback = env[RACK_EARLY_HINTS]
          env[RACK_EARLY_HINTS] = lambda do |headers|
            ## If <tt>rack.early_hints</tt> is called, it must be called with valid Rack response headers.
            check_headers(headers)
            original_callback.call(headers)
          end
        end
      end

      ##
      ## == The Response
      ##
      ## Outgoing HTTP responses are generated from the response tuple generated by the application. The response tuple is an +Array+ of three elements, which are: the HTTP status, the headers, and the response body. The Rack application is responsible for ensuring that the response tuple is well-formed and should follow the rules set out in this specification.
      ##
      ## === The Status
      ##
      def check_status(status)
        ## This is an HTTP status. It must be an Integer greater than or equal to 100.
        unless status.is_a?(Integer) && status >= 100
          raise LintError, "Status must be an Integer >=100"
        end
      end

      ##
      ## === The Headers
      ##
      def check_headers(headers)
        ## The headers must be an unfrozen +Hash+. \
        unless headers.kind_of?(Hash)
          raise LintError, "headers object should be a hash, but isn't (got #{headers.class} as headers)"
        end

        if headers.frozen?
          raise LintError, "headers object should not be frozen, but is"
        end

        headers.each do |key, value|
          ## The header keys must be +String+ values. \
          unless key.kind_of? String
            raise LintError, "header key must be a string, was #{key.class}"
          end

          ## Special headers starting <tt>rack.</tt> are for communicating with the server, and must not be sent back to the client.
          next if key.start_with?("rack.")

          ##
          ## * The headers must not contain a <tt>"status"</tt> key.
          raise LintError, "headers must not contain status" if key == "status"
          ## * Header keys must conform to {RFC7230}[https://tools.ietf.org/html/rfc7230] token specification, i.e. cannot contain non-printable ASCII, <tt>DQUOTE</tt> or <tt>(),/:;<=>?@[\]{}</tt>.
          raise LintError, "invalid header name: #{key}" if key =~ /[\(\),\/:;<=>\?@\[\\\]{}[:cntrl:]]/
          ## * Header keys must not contain uppercase ASCII characters (A-Z).
          raise LintError, "uppercase character in header name: #{key}" if key =~ /[A-Z]/

          ## * Header values must be either a +String+, \
          if value.kind_of?(String)
            check_header_value(key, value)
          elsif value.kind_of?(Array)
            ## or an +Array+ of +String+ values, \
            value.each{|value| check_header_value(key, value)}
          else
            raise LintError, "a header value must be a String or Array of Strings, but the value of '#{key}' is a #{value.class}"
          end
        end
      end

      def check_header_value(key, value)
        ## such that each +String+ must not contain <tt>NUL</tt> (<tt>\0</tt>), <tt>CR</tt> (<tt>\r</tt>), or <tt>LF</tt> (<tt>\n</tt>).
        if value.match?(/[\x00\x0A\x0D]/)
          raise LintError, "invalid header value #{key}: #{value.inspect}"
        end
      end

      ##
      ## ==== The <tt>content-type</tt> Header
      ##
      def check_content_type_header(status, headers)
        headers.each do |key, value|
          ## There must not be a <tt>content-type</tt> header key when the status is <tt>1xx</tt>, <tt>204</tt>, or <tt>304</tt>.
          if key == "content-type"
            if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.key? status.to_i
              raise LintError, "content-type header found in #{status} response, not allowed"
            end
            return
          end
        end
      end

      ##
      ## ==== The <tt>content-length</tt> Header
      ##
      def check_content_length_header(status, headers)
        headers.each do |key, value|
          if key == 'content-length'
            ## There must not be a <tt>content-length</tt> header key when the status is <tt>1xx</tt>, <tt>204</tt>, or <tt>304</tt>.
            if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.key? status.to_i
              raise LintError, "content-length header found in #{status} response, not allowed"
            end
            @content_length = value
          end
        end
      end

      def verify_content_length(size)
        if @head_request
          unless size == 0
            raise LintError, "Response body was given for HEAD request, but should be empty"
          end
        elsif @content_length
          unless @content_length == size.to_s
            raise LintError, "content-length header was #{@content_length}, but should be #{size}"
          end
        end
      end

      ##
      ## ==== The <tt>rack.protocol</tt> Header
      ##
      def check_rack_protocol_header(status, headers)
        ## If the <tt>rack.protocol</tt> header is present, it must be a +String+, and must be one of the values from the <tt>rack.protocol</tt> array from the environment.
        protocol = headers['rack.protocol']

        if protocol
          request_protocols = @env['rack.protocol']

          if request_protocols.nil?
            raise LintError, "rack.protocol header is #{protocol.inspect}, but rack.protocol was not set in request!"
          elsif !request_protocols.include?(protocol)
            raise LintError, "rack.protocol header is #{protocol.inspect}, but should be one of #{request_protocols.inspect} from the request!"
          end
        end
      end
      ##
      ## Setting this value informs the server that it should perform a connection upgrade. In HTTP/1, this is done using the +upgrade+ header. In HTTP/2+, this is done by accepting the request.
      ##
      ## === The Body
      ##
      ## The Body is typically an +Array+ of +String+ values, an enumerable that yields +String+ values, a +Proc+, or an +IO+-like object.
      ##
      ## The Body must respond to +each+ or +call+. It may optionally respond to +to_path+ or +to_ary+. A Body that responds to +each+ is considered to be an Enumerable Body. A Body that responds to +call+ is considered to be a Streaming Body.
      ##
      ## A Body that responds to both +each+ and +call+ must be treated as an Enumerable Body, not a Streaming Body. If it responds to +each+, you must call +each+ and not +call+. If the Body doesn't respond to +each+, then you can assume it responds to +call+.
      ##
      ## The Body must either be consumed or returned. The Body is consumed by optionally calling either +each+ or +call+. Then, if the Body responds to +close+, it must be called to release any resources associated with the generation of the body. In other words, +close+ must always be called at least once; typically after the web server has sent the response to the client, but also in cases where the Rack application makes internal/virtual requests and discards the response.
      def close
        ##
        ## After calling +close+, the Body is considered closed and should not be consumed again. \
        @closed = true

        ## If the original Body is replaced by a new Body, the new Body must also consume the original Body by calling +close+ if possible.
        @body.close if @body.respond_to?(:close)

        index = @lint.index(self)
        unless @env['rack.lint'][0..index].all? {|lint| lint.instance_variable_get(:@closed)}
          raise LintError, "Body has not been closed"
        end
      end

      def verify_to_path
        ##
        ## If the Body responds to +to_path+, it must return either +nil+ or a +String+. If a +String+ is returned, it must be a path for the local file system whose contents are identical to that produced by calling +each+; this may be used by the server as an alternative, possibly more efficient way to transport the response. The +to_path+ method does not consume the body.
        if @body.respond_to?(:to_path)
          optional_path = @body.to_path

          if optional_path != nil
            unless optional_path.is_a?(String) && ::File.exist?(optional_path)
              raise LintError, "body.to_path must be nil or a path to an existing file"
            end
          end
        end
      end

      ##
      ## ==== Enumerable Body
      ##
      def each
        ## The Enumerable Body must respond to +each+, \
        raise LintError, "Enumerable Body must respond to each" unless @body.respond_to?(:each)

        ## which must only be called once, \
        raise LintError, "Response body must only be called once (#{@consumed})" unless @consumed.nil?

        ## must not be called after being closed, \
        raise LintError, "Response body is already closed" if @closed

        @consumed = :each

        @body.each do |chunk|
          ## and must only yield +String+ values.
          unless chunk.kind_of? String
            raise LintError, "Body yielded non-string value #{chunk.inspect}"
          end

          ##
          ## Middleware must not call +each+ directly on the Body. Instead, middleware can return a new Body that calls +each+ on the original Body, yielding at least once per iteration.
          if @lint[0] == self
            @env['rack.lint.body_iteration'] += 1
          else
            if (@env['rack.lint.body_iteration'] -= 1) > 0
              raise LintError, "New body must yield at least once per iteration of old body"
            end
          end

          @size += chunk.bytesize
          yield chunk
        end

        verify_content_length(@size)

        verify_to_path
      end

      BODY_METHODS = {to_ary: true, each: true, call: true, to_path: true}

      def to_path
        @body.to_path
      end

      def respond_to?(name, *)
        if BODY_METHODS.key?(name)
          @body.respond_to?(name)
        else
          super
        end
      end

      ##
      ## If the Body responds to +to_ary+, it must return an +Array+ whose contents are identical to that produced by calling +each+. Middleware may call +to_ary+ directly on the Body and return a new Body in its place. In other words, middleware can only process the Body directly if it responds to +to_ary+. If the Body responds to both +to_ary+ and +close+, its implementation of +to_ary+ must call +close+.
      def to_ary
        @body.to_ary.tap do |content|
          unless content == @body.enum_for.to_a
            raise LintError, "#to_ary not identical to contents produced by calling #each"
          end
        end
      ensure
        close
      end

      ##
      ## ==== Streaming Body
      ##
      def call(stream)
        ## The Streaming Body must respond to +call+, \
        raise LintError, "Streaming Body must respond to call" unless @body.respond_to?(:call)

        ## which must only be called once, \
        raise LintError, "Response body must only be called once (#{@consumed})" unless @consumed.nil?

        ## must not be called after being closed, \
        raise LintError, "Response body is already closed" if @closed

        @consumed = :call

        ## and accept a +stream+ argument.
        ##
        ## The +stream+ argument must respond to: +read+, +write+, <tt><<</tt>, +flush+, +close+, +close_read+, +close_write+, and +closed?+. \
        @body.call(StreamWrapper.new(stream))
      end

      class StreamWrapper
        extend Forwardable

        ## The semantics of these +IO+ methods must be a best effort match to those of a normal Ruby +IO+ or +Socket+ object, using standard arguments and raising standard exceptions. Servers may simply pass on real +IO+ objects to the Streaming Body. In some cases (e.g. when using <tt>transfer-encoding</tt> or HTTP/2+), the server may need to provide a wrapper that implements the required methods, in order to provide the correct semantics.
        REQUIRED_METHODS = [
          :read, :write, :<<, :flush, :close,
          :close_read, :close_write, :closed?
        ]

        def_delegators :@stream, *REQUIRED_METHODS

        def initialize(stream)
          @stream = stream

          REQUIRED_METHODS.each do |method_name|
            raise LintError, "Stream must respond to #{method_name}" unless stream.respond_to?(method_name)
          end
        end
      end
    end
  end
end

##
## == Thanks
##
## We'd like to thank everyone who has contributed to the Rack project over the years. Your work has made this specification possible. That includes everyone who has contributed code, documentation, bug reports, and feedback. We'd also like to thank the authors of the various web servers, frameworks, and libraries that have implemented the Rack specification. Your work has helped to make the web a better place.
##
## Some parts of this specification are adapted from {PEP 333 – Python Web Server Gateway Interface v1.0}[https://peps.python.org/pep-0333/]. We'd like to thank everyone involved in that effort.
