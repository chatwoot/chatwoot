# -*- encoding: binary -*-
# frozen_string_literal: true

require 'uri'
require 'fileutils'
require 'set'
require 'tempfile'
require 'time'
require 'erb'

require_relative 'query_parser'
require_relative 'mime'
require_relative 'headers'
require_relative 'constants'

module Rack
  # Rack::Utils contains a grab-bag of useful methods for writing web
  # applications adopted from all kinds of Ruby libraries.

  module Utils
    ParameterTypeError = QueryParser::ParameterTypeError
    InvalidParameterError = QueryParser::InvalidParameterError
    ParamsTooDeepError = QueryParser::ParamsTooDeepError
    DEFAULT_SEP = QueryParser::DEFAULT_SEP
    COMMON_SEP = QueryParser::COMMON_SEP
    KeySpaceConstrainedParams = QueryParser::Params
    URI_PARSER = defined?(::URI::RFC2396_PARSER) ? ::URI::RFC2396_PARSER : ::URI::DEFAULT_PARSER

    class << self
      attr_accessor :default_query_parser
    end
    # The default amount of nesting to allowed by hash parameters.
    # This helps prevent a rogue client from triggering a possible stack overflow
    # when parsing parameters.
    self.default_query_parser = QueryParser.make_default(32)

    module_function

    # URI escapes. (CGI style space to +)
    def escape(s)
      URI.encode_www_form_component(s)
    end

    # Like URI escaping, but with %20 instead of +. Strictly speaking this is
    # true URI escaping.
    def escape_path(s)
      URI_PARSER.escape s
    end

    # Unescapes the **path** component of a URI.  See Rack::Utils.unescape for
    # unescaping query parameters or form components.
    def unescape_path(s)
      URI_PARSER.unescape s
    end

    # Unescapes a URI escaped string with +encoding+. +encoding+ will be the
    # target encoding of the string returned, and it defaults to UTF-8
    def unescape(s, encoding = Encoding::UTF_8)
      URI.decode_www_form_component(s, encoding)
    end

    class << self
      attr_accessor :multipart_total_part_limit

      attr_accessor :multipart_file_limit

      # multipart_part_limit is the original name of multipart_file_limit, but
      # the limit only counts parts with filenames.
      alias multipart_part_limit multipart_file_limit
      alias multipart_part_limit= multipart_file_limit=
    end

    # The maximum number of file parts a request can contain. Accepting too
    # many parts can lead to the server running out of file handles.
    # Set to `0` for no limit.
    self.multipart_file_limit = (ENV['RACK_MULTIPART_PART_LIMIT'] || ENV['RACK_MULTIPART_FILE_LIMIT'] || 128).to_i

    # The maximum total number of parts a request can contain. Accepting too
    # many can lead to excessive memory use and parsing time.
    self.multipart_total_part_limit = (ENV['RACK_MULTIPART_TOTAL_PART_LIMIT'] || 4096).to_i

    def self.param_depth_limit
      default_query_parser.param_depth_limit
    end

    def self.param_depth_limit=(v)
      self.default_query_parser = self.default_query_parser.new_depth_limit(v)
    end

    if defined?(Process::CLOCK_MONOTONIC)
      def clock_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    else
      # :nocov:
      def clock_time
        Time.now.to_f
      end
      # :nocov:
    end

    def parse_query(qs, d = nil, &unescaper)
      Rack::Utils.default_query_parser.parse_query(qs, d, &unescaper)
    end

    def parse_nested_query(qs, d = nil)
      Rack::Utils.default_query_parser.parse_nested_query(qs, d)
    end

    def build_query(params)
      params.map { |k, v|
        if v.class == Array
          build_query(v.map { |x| [k, x] })
        else
          v.nil? ? escape(k) : "#{escape(k)}=#{escape(v)}"
        end
      }.join("&")
    end

    def build_nested_query(value, prefix = nil)
      case value
      when Array
        value.map { |v|
          build_nested_query(v, "#{prefix}[]")
        }.join("&")
      when Hash
        value.map { |k, v|
          build_nested_query(v, prefix ? "#{prefix}[#{k}]" : k)
        }.delete_if(&:empty?).join('&')
      when nil
        escape(prefix)
      else
        raise ArgumentError, "value must be a Hash" if prefix.nil?
        "#{escape(prefix)}=#{escape(value)}"
      end
    end

    def q_values(q_value_header)
      q_value_header.to_s.split(',').map do |part|
        value, parameters = part.split(';', 2).map(&:strip)
        quality = 1.0
        if parameters && (md = /\Aq=([\d.]+)/.match(parameters))
          quality = md[1].to_f
        end
        [value, quality]
      end
    end

    def forwarded_values(forwarded_header)
      return nil unless forwarded_header
      forwarded_header = forwarded_header.to_s.gsub("\n", ";")

      forwarded_header.split(';').each_with_object({}) do |field, values|
        field.split(',').each do |pair|
          pair = pair.split('=').map(&:strip).join('=')
          return nil unless pair =~ /\A(by|for|host|proto)="?([^"]+)"?\Z/i
          (values[$1.downcase.to_sym] ||= []) << $2
        end
      end
    end
    module_function :forwarded_values

    # Return best accept value to use, based on the algorithm
    # in RFC 2616 Section 14.  If there are multiple best
    # matches (same specificity and quality), the value returned
    # is arbitrary.
    def best_q_match(q_value_header, available_mimes)
      values = q_values(q_value_header)

      matches = values.map do |req_mime, quality|
        match = available_mimes.find { |am| Rack::Mime.match?(am, req_mime) }
        next unless match
        [match, quality]
      end.compact.sort_by do |match, quality|
        (match.split('/', 2).count('*') * -10) + quality
      end.last
      matches&.first
    end

    # Introduced in ERB 4.0. ERB::Escape is an alias for ERB::Utils which
    # doesn't get monkey-patched by rails
    if defined?(ERB::Escape) && ERB::Escape.instance_method(:html_escape)
      define_method(:escape_html, ERB::Escape.instance_method(:html_escape))
    # :nocov:
    # Ruby 3.2/ERB 4.0 added ERB::Escape#html_escape, so the else
    # branch cannot be hit on the current Ruby version.
    else
      require 'cgi/escape'
      # Escape ampersands, brackets and quotes to their HTML/XML entities.
      def escape_html(string)
        CGI.escapeHTML(string.to_s)
      end
    # :nocov:
    end

    def select_best_encoding(available_encodings, accept_encoding)
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html

      expanded_accept_encoding = []

      accept_encoding.each do |m, q|
        preference = available_encodings.index(m) || available_encodings.size

        if m == "*"
          (available_encodings - accept_encoding.map(&:first)).each do |m2|
            expanded_accept_encoding << [m2, q, preference]
          end
        else
          expanded_accept_encoding << [m, q, preference]
        end
      end

      encoding_candidates = expanded_accept_encoding
        .sort_by { |_, q, p| [-q, p] }
        .map!(&:first)

      unless encoding_candidates.include?("identity")
        encoding_candidates.push("identity")
      end

      expanded_accept_encoding.each do |m, q|
        encoding_candidates.delete(m) if q == 0.0
      end

      (encoding_candidates & available_encodings)[0]
    end

    # :call-seq:
    #   parse_cookies_header(value) -> hash
    #
    # Parse cookies from the provided header +value+ according to RFC6265. The
    # syntax for cookie headers only supports semicolons. Returns a map of
    # cookie +key+ to cookie +value+.
    #
    #   parse_cookies_header('myname=myvalue; max-age=0')
    #   # => {"myname"=>"myvalue", "max-age"=>"0"}
    #
    def parse_cookies_header(value)
      return {} unless value

      value.split(/; */n).each_with_object({}) do |cookie, cookies|
        next if cookie.empty?
        key, value = cookie.split('=', 2)
        cookies[key] = (unescape(value) rescue value) unless cookies.key?(key)
      end
    end

    # :call-seq:
    #   parse_cookies(env) -> hash
    #
    # Parse cookies from the provided request environment using
    # parse_cookies_header. Returns a map of cookie +key+ to cookie +value+.
    #
    #   parse_cookies({'HTTP_COOKIE' => 'myname=myvalue'})
    #   # => {'myname' => 'myvalue'}
    #
    def parse_cookies(env)
      parse_cookies_header env[HTTP_COOKIE]
    end

    # A valid cookie key according to RFC6265 and RFC2616.
    # A <cookie-name> can be any US-ASCII characters, except control characters, spaces, or tabs. It also must not contain a separator character like the following: ( ) < > @ , ; : \ " / [ ] ? = { }.
    VALID_COOKIE_KEY = /\A[!#$%&'*+\-\.\^_`|~0-9a-zA-Z]+\z/.freeze
    private_constant :VALID_COOKIE_KEY

    # :call-seq:
    #   set_cookie_header(key, value) -> encoded string
    #
    # Generate an encoded string using the provided +key+ and +value+ suitable
    # for the +set-cookie+ header according to RFC6265. The +value+ may be an
    # instance of either +String+ or +Hash+. If the cookie key is invalid (as
    # defined by RFC6265), an +ArgumentError+ will be raised.
    #
    # If the cookie +value+ is an instance of +Hash+, it considers the following
    # cookie attribute keys: +domain+, +max_age+, +expires+ (must be instance
    # of +Time+), +secure+, +http_only+, +same_site+ and +value+. For more
    # details about the interpretation of these fields, consult
    # [RFC6265 Section 5.2](https://datatracker.ietf.org/doc/html/rfc6265#section-5.2).
    #
    #   set_cookie_header("myname", "myvalue")
    #   # => "myname=myvalue"
    #
    #   set_cookie_header("myname", {value: "myvalue", max_age: 10})
    #   # => "myname=myvalue; max-age=10"
    #
    def set_cookie_header(key, value)
      unless key =~ VALID_COOKIE_KEY
        raise ArgumentError, "invalid cookie key: #{key.inspect}"
      end

      case value
      when Hash
        domain  = "; domain=#{value[:domain]}"   if value[:domain]
        path    = "; path=#{value[:path]}"       if value[:path]
        max_age = "; max-age=#{value[:max_age]}" if value[:max_age]
        expires = "; expires=#{value[:expires].httpdate}" if value[:expires]
        secure = "; secure"  if value[:secure]
        httponly = "; httponly" if (value.key?(:httponly) ? value[:httponly] : value[:http_only])
        same_site =
          case value[:same_site]
          when false, nil
            nil
          when :none, 'None', :None
            '; samesite=none'
          when :lax, 'Lax', :Lax
            '; samesite=lax'
          when true, :strict, 'Strict', :Strict
            '; samesite=strict'
          else
            raise ArgumentError, "Invalid :same_site value: #{value[:same_site].inspect}"
          end
        partitioned = "; partitioned" if value[:partitioned]
        value = value[:value]
      end

      value = [value] unless Array === value

      return "#{key}=#{value.map { |v| escape v }.join('&')}#{domain}" \
        "#{path}#{max_age}#{expires}#{secure}#{httponly}#{same_site}#{partitioned}"
    end

    # :call-seq:
    #   set_cookie_header!(headers, key, value) -> header value
    #
    # Append a cookie in the specified headers with the given cookie +key+ and
    # +value+ using set_cookie_header.
    #
    # If the headers already contains a +set-cookie+ key, it will be converted
    # to an +Array+ if not already, and appended to.
    def set_cookie_header!(headers, key, value)
      if header = headers[SET_COOKIE]
        if header.is_a?(Array)
          header << set_cookie_header(key, value)
        else
          headers[SET_COOKIE] = [header, set_cookie_header(key, value)]
        end
      else
        headers[SET_COOKIE] = set_cookie_header(key, value)
      end
    end

    # :call-seq:
    #   delete_set_cookie_header(key, value = {}) -> encoded string
    #
    # Generate an encoded string based on the given +key+ and +value+ using
    # set_cookie_header for the purpose of causing the specified cookie to be
    # deleted. The +value+ may be an instance of +Hash+ and can include
    # attributes as outlined by set_cookie_header. The encoded cookie will have
    # a +max_age+ of 0 seconds, an +expires+ date in the past and an empty
    # +value+. When used with the +set-cookie+ header, it will cause the client
    # to *remove* any matching cookie.
    #
    #   delete_set_cookie_header("myname")
    #   # => "myname=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT"
    #
    def delete_set_cookie_header(key, value = {})
      set_cookie_header(key, value.merge(max_age: '0', expires: Time.at(0), value: ''))
    end

    def delete_cookie_header!(headers, key, value = {})
      headers[SET_COOKIE] = delete_set_cookie_header!(headers[SET_COOKIE], key, value)

      return nil
    end

    # :call-seq:
    #   delete_set_cookie_header!(header, key, value = {}) -> header value
    #
    # Set an expired cookie in the specified headers with the given cookie
    # +key+ and +value+ using delete_set_cookie_header. This causes
    # the client to immediately delete the specified cookie.
    #
    #   delete_set_cookie_header!(nil, "mycookie")
    #   # => "mycookie=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT"
    #
    # If the header is non-nil, it will be modified in place.
    #
    #   header = []
    #   delete_set_cookie_header!(header, "mycookie")
    #   # => ["mycookie=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT"]
    #   header
    #   # => ["mycookie=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT"]
    #
    def delete_set_cookie_header!(header, key, value = {})
      if header
        header = Array(header)
        header << delete_set_cookie_header(key, value)
      else
        header = delete_set_cookie_header(key, value)
      end

      return header
    end

    def rfc2822(time)
      time.rfc2822
    end

    # Parses the "Range:" header, if present, into an array of Range objects.
    # Returns nil if the header is missing or syntactically invalid.
    # Returns an empty array if none of the ranges are satisfiable.
    def byte_ranges(env, size)
      get_byte_ranges env['HTTP_RANGE'], size
    end

    def get_byte_ranges(http_range, size)
      # See <http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35>
      # Ignore Range when file size is 0 to avoid a 416 error.
      return nil if size.zero?
      return nil unless http_range && http_range =~ /bytes=([^;]+)/
      ranges = []
      $1.split(/,[ \t]*/).each do |range_spec|
        return nil unless range_spec.include?('-')
        range = range_spec.split('-')
        r0, r1 = range[0], range[1]
        if r0.nil? || r0.empty?
          return nil if r1.nil?
          # suffix-byte-range-spec, represents trailing suffix of file
          r0 = size - r1.to_i
          r0 = 0  if r0 < 0
          r1 = size - 1
        else
          r0 = r0.to_i
          if r1.nil?
            r1 = size - 1
          else
            r1 = r1.to_i
            return nil  if r1 < r0  # backwards range is syntactically invalid
            r1 = size - 1  if r1 >= size
          end
        end
        ranges << (r0..r1)  if r0 <= r1
      end

      return [] if ranges.map(&:size).sum > size

      ranges
    end

    # :nocov:
    if defined?(OpenSSL.fixed_length_secure_compare)
      # Constant time string comparison.
      #
      # NOTE: the values compared should be of fixed length, such as strings
      # that have already been processed by HMAC. This should not be used
      # on variable length plaintext strings because it could leak length info
      # via timing attacks.
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        OpenSSL.fixed_length_secure_compare(a, b)
      end
    # :nocov:
    else
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        l = a.unpack("C*")

        r, i = 0, -1
        b.each_byte { |v| r |= v ^ l[i += 1] }
        r == 0
      end
    end

    # Context allows the use of a compatible middleware at different points
    # in a request handling stack. A compatible middleware must define
    # #context which should take the arguments env and app. The first of which
    # would be the request environment. The second of which would be the rack
    # application that the request would be forwarded to.
    class Context
      attr_reader :for, :app

      def initialize(app_f, app_r)
        raise 'running context does not respond to #context' unless app_f.respond_to? :context
        @for, @app = app_f, app_r
      end

      def call(env)
        @for.context(env, @app)
      end

      def recontext(app)
        self.class.new(@for, app)
      end

      def context(env, app = @app)
        recontext(app).call(env)
      end
    end

    # Every standard HTTP code mapped to the appropriate message.
    # Generated with:
    #   curl -s https://www.iana.org/assignments/http-status-codes/http-status-codes-1.csv \
    #     | ruby -rcsv -e "puts CSV.parse(STDIN, headers: true) \
    #     .reject {|v| v['Description'] == 'Unassigned' or v['Description'].include? '(' } \
    #     .map {|v| %Q/#{v['Value']} => '#{v['Description']}'/ }.join(','+?\n)"
    HTTP_STATUS_CODES = {
      100 => 'Continue',
      101 => 'Switching Protocols',
      102 => 'Processing',
      103 => 'Early Hints',
      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      203 => 'Non-Authoritative Information',
      204 => 'No Content',
      205 => 'Reset Content',
      206 => 'Partial Content',
      207 => 'Multi-Status',
      208 => 'Already Reported',
      226 => 'IM Used',
      300 => 'Multiple Choices',
      301 => 'Moved Permanently',
      302 => 'Found',
      303 => 'See Other',
      304 => 'Not Modified',
      305 => 'Use Proxy',
      307 => 'Temporary Redirect',
      308 => 'Permanent Redirect',
      400 => 'Bad Request',
      401 => 'Unauthorized',
      402 => 'Payment Required',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      406 => 'Not Acceptable',
      407 => 'Proxy Authentication Required',
      408 => 'Request Timeout',
      409 => 'Conflict',
      410 => 'Gone',
      411 => 'Length Required',
      412 => 'Precondition Failed',
      413 => 'Content Too Large',
      414 => 'URI Too Long',
      415 => 'Unsupported Media Type',
      416 => 'Range Not Satisfiable',
      417 => 'Expectation Failed',
      421 => 'Misdirected Request',
      422 => 'Unprocessable Content',
      423 => 'Locked',
      424 => 'Failed Dependency',
      425 => 'Too Early',
      426 => 'Upgrade Required',
      428 => 'Precondition Required',
      429 => 'Too Many Requests',
      431 => 'Request Header Fields Too Large',
      451 => 'Unavailable For Legal Reasons',
      500 => 'Internal Server Error',
      501 => 'Not Implemented',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout',
      505 => 'HTTP Version Not Supported',
      506 => 'Variant Also Negotiates',
      507 => 'Insufficient Storage',
      508 => 'Loop Detected',
      511 => 'Network Authentication Required'
    }

    # Responses with HTTP status codes that should not have an entity body
    STATUS_WITH_NO_ENTITY_BODY = Hash[((100..199).to_a << 204 << 304).product([true])]

    SYMBOL_TO_STATUS_CODE = Hash[*HTTP_STATUS_CODES.map { |code, message|
      [message.downcase.gsub(/\s|-/, '_').to_sym, code]
    }.flatten]

    OBSOLETE_SYMBOLS_TO_STATUS_CODES = {
      payload_too_large: 413,
      unprocessable_entity: 422,
      bandwidth_limit_exceeded: 509,
      not_extended: 510
    }.freeze
    private_constant :OBSOLETE_SYMBOLS_TO_STATUS_CODES

    OBSOLETE_SYMBOL_MAPPINGS = {
      payload_too_large: :content_too_large,
      unprocessable_entity: :unprocessable_content
    }.freeze
    private_constant :OBSOLETE_SYMBOL_MAPPINGS

    def status_code(status)
      if status.is_a?(Symbol)
        SYMBOL_TO_STATUS_CODE.fetch(status) do
          fallback_code = OBSOLETE_SYMBOLS_TO_STATUS_CODES.fetch(status) { raise ArgumentError, "Unrecognized status code #{status.inspect}" }
          message = "Status code #{status.inspect} is deprecated and will be removed in a future version of Rack."
          if canonical_symbol = OBSOLETE_SYMBOL_MAPPINGS[status]
            message = "#{message} Please use #{canonical_symbol.inspect} instead."
          end
          warn message, uplevel: 3
          fallback_code
        end
      else
        status.to_i
      end
    end

    PATH_SEPS = Regexp.union(*[::File::SEPARATOR, ::File::ALT_SEPARATOR].compact)

    def clean_path_info(path_info)
      parts = path_info.split PATH_SEPS

      clean = []

      parts.each do |part|
        next if part.empty? || part == '.'
        part == '..' ? clean.pop : clean << part
      end

      clean_path = clean.join(::File::SEPARATOR)
      clean_path.prepend("/") if parts.empty? || parts.first.empty?
      clean_path
    end

    NULL_BYTE = "\0"

    def valid_path?(path)
      path.valid_encoding? && !path.include?(NULL_BYTE)
    end

  end
end
