# frozen_string_literal: true

require 'pathname'
require 'net/http'
require 'uri'
require 'zlib'
require 'multi_xml'
require 'mini_mime'
require 'json'
require 'csv'

require 'httparty/module_inheritable_attributes'
require 'httparty/cookie_hash'
require 'httparty/net_digest_auth'
require 'httparty/version'
require 'httparty/connection_adapter'
require 'httparty/logger/logger'
require 'httparty/request/body'
require 'httparty/response_fragment'
require 'httparty/decompressor'
require 'httparty/text_encoder'
require 'httparty/headers_processor'

# @see HTTParty::ClassMethods
module HTTParty
  def self.included(base)
    base.extend ClassMethods
    base.send :include, ModuleInheritableAttributes
    base.send(:mattr_inheritable, :default_options)
    base.send(:mattr_inheritable, :default_cookies)
    base.instance_variable_set(:@default_options, {})
    base.instance_variable_set(:@default_cookies, CookieHash.new)
  end

  # == Common Request Options
  # Request methods (get, post, patch, put, delete, head, options) all take a common set of options. These are:
  #
  # [:+body+:] Body of the request. If passed an object that responds to #to_hash, will try to normalize it first, by default passing it to ActiveSupport::to_params. Any other kind of object will get used as-is.
  # [:+http_proxyaddr+:] Address of proxy server to use.
  # [:+http_proxyport+:]  Port of proxy server to use.
  # [:+http_proxyuser+:] User for proxy server authentication.
  # [:+http_proxypass+:] Password for proxy server authentication.
  # [:+limit+:] Maximum number of redirects to follow. Takes precedences over :+no_follow+.
  # [:+query+:] Query string, or an object that responds to #to_hash representing it. Normalized according to the same rules as :+body+. If you specify this on a POST, you must use an object which responds to #to_hash. See also HTTParty::ClassMethods.default_params.
  # [:+timeout+:] Timeout for opening connection and reading data.
  # [:+local_host+:] Local address to bind to before connecting.
  # [:+local_port+:] Local port to bind to before connecting.
  # [:+body_stream+:] Allow streaming to a REST server to specify a body_stream.
  # [:+stream_body+:] Allow for streaming large files without loading them into memory.
  # [:+multipart+:] Force content-type to be multipart
  #
  # There are also another set of options with names corresponding to various class methods. The methods in question are those that let you set a class-wide default, and the options override the defaults on a request-by-request basis. Those options are:
  # * :+base_uri+: see HTTParty::ClassMethods.base_uri.
  # * :+basic_auth+: see HTTParty::ClassMethods.basic_auth. Only one of :+basic_auth+ and :+digest_auth+ can be used at a time; if you try using both, you'll get an ArgumentError.
  # * :+debug_output+: see HTTParty::ClassMethods.debug_output.
  # * :+digest_auth+: see HTTParty::ClassMethods.digest_auth. Only one of :+basic_auth+ and :+digest_auth+ can be used at a time; if you try using both, you'll get an ArgumentError.
  # * :+format+: see HTTParty::ClassMethods.format.
  # * :+headers+: see HTTParty::ClassMethods.headers. Must be a an object which responds to #to_hash.
  # * :+maintain_method_across_redirects+: see HTTParty::ClassMethods.maintain_method_across_redirects.
  # * :+no_follow+: see HTTParty::ClassMethods.no_follow.
  # * :+parser+: see HTTParty::ClassMethods.parser.
  # * :+uri_adapter+: see HTTParty::ClassMethods.uri_adapter
  # * :+connection_adapter+: see HTTParty::ClassMethods.connection_adapter.
  # * :+pem+: see HTTParty::ClassMethods.pem.
  # * :+query_string_normalizer+: see HTTParty::ClassMethods.query_string_normalizer
  # * :+ssl_ca_file+: see HTTParty::ClassMethods.ssl_ca_file.
  # * :+ssl_ca_path+: see HTTParty::ClassMethods.ssl_ca_path.

  module ClassMethods
    # Turns on logging
    #
    #   class Foo
    #     include HTTParty
    #     logger Logger.new('http_logger'), :info, :apache
    #   end
    def logger(logger, level = :info, format = :apache)
      default_options[:logger]     = logger
      default_options[:log_level]  = level
      default_options[:log_format] = format
    end

    # Raises HTTParty::ResponseError if response's code matches this statuses
    #
    #   class Foo
    #     include HTTParty
    #     raise_on [404, 500]
    #   end
    def raise_on(codes = [])
      default_options[:raise_on] = *codes
    end

    # Allows setting http proxy information to be used
    #
    #   class Foo
    #     include HTTParty
    #     http_proxy 'http://foo.com', 80, 'user', 'pass'
    #   end
    def http_proxy(addr = nil, port = nil, user = nil, pass = nil)
      default_options[:http_proxyaddr] = addr
      default_options[:http_proxyport] = port
      default_options[:http_proxyuser] = user
      default_options[:http_proxypass] = pass
    end

    # Allows setting a base uri to be used for each request.
    # Will normalize uri to include http, etc.
    #
    #   class Foo
    #     include HTTParty
    #     base_uri 'twitter.com'
    #   end
    def base_uri(uri = nil)
      return default_options[:base_uri] unless uri
      default_options[:base_uri] = HTTParty.normalize_base_uri(uri)
    end

    # Allows setting basic authentication username and password.
    #
    #   class Foo
    #     include HTTParty
    #     basic_auth 'username', 'password'
    #   end
    def basic_auth(u, p)
      default_options[:basic_auth] = {username: u, password: p}
    end

    # Allows setting digest authentication username and password.
    #
    #   class Foo
    #     include HTTParty
    #     digest_auth 'username', 'password'
    #   end
    def digest_auth(u, p)
      default_options[:digest_auth] = {username: u, password: p}
    end

    # Do not send rails style query strings.
    # Specifically, don't use bracket notation when sending an array
    #
    # For a query:
    #   get '/', query: {selected_ids: [1,2,3]}
    #
    # The default query string looks like this:
    #   /?selected_ids[]=1&selected_ids[]=2&selected_ids[]=3
    #
    # Call `disable_rails_query_string_format` to transform the query string
    # into:
    #   /?selected_ids=1&selected_ids=2&selected_ids=3
    #
    # @example
    #   class Foo
    #     include HTTParty
    #     disable_rails_query_string_format
    #   end
    def disable_rails_query_string_format
      query_string_normalizer Request::NON_RAILS_QUERY_STRING_NORMALIZER
    end

    # Allows setting default parameters to be appended to each request.
    # Great for api keys and such.
    #
    #   class Foo
    #     include HTTParty
    #     default_params api_key: 'secret', another: 'foo'
    #   end
    def default_params(h = {})
      raise ArgumentError, 'Default params must be an object which responds to #to_hash' unless h.respond_to?(:to_hash)
      default_options[:default_params] ||= {}
      default_options[:default_params].merge!(h)
    end

    # Allows setting a default timeout for all HTTP calls
    # Timeout is specified in seconds.
    #
    #   class Foo
    #     include HTTParty
    #     default_timeout 10
    #   end
    def default_timeout(value)
      validate_timeout_argument(__method__, value)
      default_options[:timeout] = value
    end

    # Allows setting a default open_timeout for all HTTP calls in seconds
    #
    #   class Foo
    #     include HTTParty
    #     open_timeout 10
    #   end
    def open_timeout(value)
      validate_timeout_argument(__method__, value)
      default_options[:open_timeout] = value
    end

    # Allows setting a default read_timeout for all HTTP calls in seconds
    #
    #   class Foo
    #     include HTTParty
    #     read_timeout 10
    #   end
    def read_timeout(value)
      validate_timeout_argument(__method__, value)
      default_options[:read_timeout] = value
    end

    # Allows setting a default write_timeout for all HTTP calls in seconds
    # Supported by Ruby > 2.6.0
    #
    #   class Foo
    #     include HTTParty
    #     write_timeout 10
    #   end
    def write_timeout(value)
      validate_timeout_argument(__method__, value)
      default_options[:write_timeout] = value
    end


    # Set an output stream for debugging, defaults to $stderr.
    # The output stream is passed on to Net::HTTP#set_debug_output.
    #
    #   class Foo
    #     include HTTParty
    #     debug_output $stderr
    #   end
    def debug_output(stream = $stderr)
      default_options[:debug_output] = stream
    end

    # Allows setting HTTP headers to be used for each request.
    #
    #   class Foo
    #     include HTTParty
    #     headers 'Accept' => 'text/html'
    #   end
    def headers(h = nil)
      if h
        raise ArgumentError, 'Headers must be an object which responds to #to_hash' unless h.respond_to?(:to_hash)
        default_options[:headers] ||= {}
        default_options[:headers].merge!(h.to_hash)
      else
        default_options[:headers] || {}
      end
    end

    def cookies(h = {})
      raise ArgumentError, 'Cookies must be an object which responds to #to_hash' unless h.respond_to?(:to_hash)
      default_cookies.add_cookies(h)
    end

    # Proceed to the location header when an HTTP response dictates a redirect.
    # Redirects are always followed by default.
    #
    # @example
    #   class Foo
    #     include HTTParty
    #     base_uri 'http://google.com'
    #     follow_redirects true
    #   end
    def follow_redirects(value = true)
      default_options[:follow_redirects] = value
    end

    # Allows setting the format with which to parse.
    # Must be one of the allowed formats ie: json, xml
    #
    #   class Foo
    #     include HTTParty
    #     format :json
    #   end
    def format(f = nil)
      if f.nil?
        default_options[:format]
      else
        parser(Parser) if parser.nil?
        default_options[:format] = f
        validate_format
      end
    end

    # Declare whether or not to follow redirects.  When true, an
    # {HTTParty::RedirectionTooDeep} error will raise upon encountering a
    # redirect. You can then gain access to the response object via
    # HTTParty::RedirectionTooDeep#response.
    #
    # @see HTTParty::ResponseError#response
    #
    # @example
    #   class Foo
    #     include HTTParty
    #     base_uri 'http://google.com'
    #     no_follow true
    #   end
    #
    #   begin
    #     Foo.get('/')
    #   rescue HTTParty::RedirectionTooDeep => e
    #     puts e.response.body
    #   end
    def no_follow(value = false)
      default_options[:no_follow] = value
    end

    # Declare that you wish to maintain the chosen HTTP method across redirects.
    # The default behavior is to follow redirects via the GET method, except
    # if you are making a HEAD request, in which case the default is to
    # follow all redirects with HEAD requests.
    # If you wish to maintain the original method, you can set this option to true.
    #
    # @example
    #   class Foo
    #     include HTTParty
    #     base_uri 'http://google.com'
    #     maintain_method_across_redirects true
    #   end

    def maintain_method_across_redirects(value = true)
      default_options[:maintain_method_across_redirects] = value
    end

    # Declare that you wish to resend the full HTTP request across redirects,
    # even on redirects that should logically become GET requests.
    # A 303 redirect in HTTP signifies that the redirected url should normally
    # retrieved using a GET request, for instance, it is the output of a previous
    # POST. maintain_method_across_redirects respects this behavior, but you
    # can force HTTParty to resend_on_redirect even on 303 responses.
    #
    # @example
    #   class Foo
    #     include HTTParty
    #     base_uri 'http://google.com'
    #     resend_on_redirect
    #   end

    def resend_on_redirect(value = true)
      default_options[:resend_on_redirect] = value
    end

    # Allows setting a PEM file to be used
    #
    #   class Foo
    #     include HTTParty
    #     pem File.read('/home/user/my.pem'), "optional password"
    #   end
    def pem(pem_contents, password = nil)
      default_options[:pem] = pem_contents
      default_options[:pem_password] = password
    end

    # Allows setting a PKCS12 file to be used
    #
    #   class Foo
    #     include HTTParty
    #     pkcs12 File.read('/home/user/my.p12'), "password"
    #   end
    def pkcs12(p12_contents, password)
      default_options[:p12] = p12_contents
      default_options[:p12_password] = password
    end

    # Override the way query strings are normalized.
    # Helpful for overriding the default rails normalization of Array queries.
    #
    # For a query:
    #   get '/', query: {selected_ids: [1,2,3]}
    #
    # The default query string normalizer returns:
    #   /?selected_ids[]=1&selected_ids[]=2&selected_ids[]=3
    #
    # Let's change it to this:
    #  /?selected_ids=1&selected_ids=2&selected_ids=3
    #
    # Pass a Proc to the query normalizer which accepts the yielded query.
    #
    # @example Modifying Array query strings
    #   class ServiceWrapper
    #     include HTTParty
    #
    #     query_string_normalizer proc { |query|
    #       query.map do |key, value|
    #         value.map {|v| "#{key}=#{v}"}
    #       end.join('&')
    #     }
    #   end
    #
    # @param [Proc] normalizer custom query string normalizer.
    # @yield [Hash, String] query string
    # @yieldreturn [Array] an array that will later be joined with '&'
    def query_string_normalizer(normalizer)
      default_options[:query_string_normalizer] = normalizer
    end

    # Allows setting of SSL version to use. This only works in Ruby 1.9+.
    # You can get a list of valid versions from OpenSSL::SSL::SSLContext::METHODS.
    #
    #   class Foo
    #     include HTTParty
    #     ssl_version :SSLv3
    #   end
    def ssl_version(version)
      default_options[:ssl_version] = version
    end

    # Deactivate automatic decompression of the response body.
    # This will require you to explicitly handle body decompression
    # by inspecting the Content-Encoding response header.
    #
    # Refer to docs/README.md "HTTP Compression" section for
    # further details.
    #
    # @example
    #   class Foo
    #     include HTTParty
    #     skip_decompression
    #   end
    def skip_decompression(value = true)
      default_options[:skip_decompression] = !!value
    end

    # Allows setting of SSL ciphers to use.  This only works in Ruby 1.9+.
    # You can get a list of valid specific ciphers from OpenSSL::Cipher.ciphers.
    # You also can specify a cipher suite here, listed here at openssl.org:
    # http://www.openssl.org/docs/apps/ciphers.html#CIPHER_SUITE_NAMES
    #
    #   class Foo
    #     include HTTParty
    #     ciphers "RC4-SHA"
    #   end
    def ciphers(cipher_names)
      default_options[:ciphers] = cipher_names
    end

    # Allows setting an OpenSSL certificate authority file.  The file
    # should contain one or more certificates in PEM format.
    #
    # Setting this option enables certificate verification.  All
    # certificates along a chain must be available in ssl_ca_file or
    # ssl_ca_path for verification to succeed.
    #
    #
    #   class Foo
    #     include HTTParty
    #     ssl_ca_file '/etc/ssl/certs/ca-certificates.crt'
    #   end
    def ssl_ca_file(path)
      default_options[:ssl_ca_file] = path
    end

    # Allows setting an OpenSSL certificate authority path (directory).
    #
    # Setting this option enables certificate verification.  All
    # certificates along a chain must be available in ssl_ca_file or
    # ssl_ca_path for verification to succeed.
    #
    #   class Foo
    #     include HTTParty
    #     ssl_ca_path '/etc/ssl/certs/'
    #   end
    def ssl_ca_path(path)
      default_options[:ssl_ca_path] = path
    end

    # Allows setting a custom parser for the response.
    #
    #   class Foo
    #     include HTTParty
    #     parser Proc.new {|data| ...}
    #   end
    def parser(custom_parser = nil)
      if custom_parser.nil?
        default_options[:parser]
      else
        default_options[:parser] = custom_parser
        validate_format
      end
    end

    # Allows setting a custom URI adapter.
    #
    #   class Foo
    #     include HTTParty
    #     uri_adapter Addressable::URI
    #   end
    def uri_adapter(uri_adapter)
      raise ArgumentError, 'The URI adapter should respond to #parse' unless uri_adapter.respond_to?(:parse)
      default_options[:uri_adapter] = uri_adapter
    end

    # Allows setting a custom connection_adapter for the http connections
    #
    # @example
    #   class Foo
    #     include HTTParty
    #     connection_adapter Proc.new {|uri, options| ... }
    #   end
    #
    # @example provide optional configuration for your connection_adapter
    #   class Foo
    #     include HTTParty
    #     connection_adapter Proc.new {|uri, options| ... }, {foo: :bar}
    #   end
    #
    # @see HTTParty::ConnectionAdapter
    def connection_adapter(custom_adapter = nil, options = nil)
      if custom_adapter.nil?
        default_options[:connection_adapter]
      else
        default_options[:connection_adapter] = custom_adapter
        default_options[:connection_adapter_options] = options
      end
    end

    # Allows making a get request to a url.
    #
    #   class Foo
    #     include HTTParty
    #   end
    #
    #   # Simple get with full url
    #   Foo.get('http://foo.com/resource.json')
    #
    #   # Simple get with full url and query parameters
    #   # ie: http://foo.com/resource.json?limit=10
    #   Foo.get('http://foo.com/resource.json', query: {limit: 10})
    def get(path, options = {}, &block)
      perform_request Net::HTTP::Get, path, options, &block
    end

    # Allows making a post request to a url.
    #
    #   class Foo
    #     include HTTParty
    #   end
    #
    #   # Simple post with full url and setting the body
    #   Foo.post('http://foo.com/resources', body: {bar: 'baz'})
    #
    #   # Simple post with full url using :query option,
    #   # which appends the parameters to the URI.
    #   Foo.post('http://foo.com/resources', query: {bar: 'baz'})
    def post(path, options = {}, &block)
      perform_request Net::HTTP::Post, path, options, &block
    end

    # Perform a PATCH request to a path
    def patch(path, options = {}, &block)
      perform_request Net::HTTP::Patch, path, options, &block
    end

    # Perform a PUT request to a path
    def put(path, options = {}, &block)
      perform_request Net::HTTP::Put, path, options, &block
    end

    # Perform a DELETE request to a path
    def delete(path, options = {}, &block)
      perform_request Net::HTTP::Delete, path, options, &block
    end

    # Perform a MOVE request to a path
    def move(path, options = {}, &block)
      perform_request Net::HTTP::Move, path, options, &block
    end

    # Perform a COPY request to a path
    def copy(path, options = {}, &block)
      perform_request Net::HTTP::Copy, path, options, &block
    end

    # Perform a HEAD request to a path
    def head(path, options = {}, &block)
      ensure_method_maintained_across_redirects options
      perform_request Net::HTTP::Head, path, options, &block
    end

    # Perform an OPTIONS request to a path
    def options(path, options = {}, &block)
      perform_request Net::HTTP::Options, path, options, &block
    end

    # Perform a MKCOL request to a path
    def mkcol(path, options = {}, &block)
      perform_request Net::HTTP::Mkcol, path, options, &block
    end

    def lock(path, options = {}, &block)
      perform_request Net::HTTP::Lock, path, options, &block
    end

    def unlock(path, options = {}, &block)
      perform_request Net::HTTP::Unlock, path, options, &block
    end

    attr_reader :default_options

    private

    def validate_timeout_argument(timeout_type, value)
      raise ArgumentError, "#{ timeout_type } must be an integer or float" unless value && (value.is_a?(Integer) || value.is_a?(Float))
    end

    def ensure_method_maintained_across_redirects(options)
      unless options.key?(:maintain_method_across_redirects)
        options[:maintain_method_across_redirects] = true
      end
    end

    def perform_request(http_method, path, options, &block) #:nodoc:
      options = ModuleInheritableAttributes.hash_deep_dup(default_options).merge(options)
      HeadersProcessor.new(headers, options).call
      process_cookies(options)
      Request.new(http_method, path, options).perform(&block)
    end

    def process_cookies(options) #:nodoc:
      return unless options[:cookies] || default_cookies.any?
      options[:headers] ||= headers.dup
      options[:headers]['cookie'] = cookies.merge(options.delete(:cookies) || {}).to_cookie_string
    end

    def validate_format
      if format && parser.respond_to?(:supports_format?) && !parser.supports_format?(format)
        supported_format_names = parser.supported_formats.map(&:to_s).sort.join(', ')
        raise UnsupportedFormat, "'#{format.inspect}' Must be one of: #{supported_format_names}"
      end
    end
  end

  def self.normalize_base_uri(url) #:nodoc:
    normalized_url = url.dup
    use_ssl = (normalized_url =~ /^https/) || (normalized_url =~ /:443\b/)
    ends_with_slash = normalized_url =~ /\/$/

    normalized_url.chop! if ends_with_slash
    normalized_url.gsub!(/^https?:\/\//i, '')

    "http#{'s' if use_ssl}://#{normalized_url}"
  end

  class Basement #:nodoc:
    include HTTParty
  end

  def self.get(*args, &block)
    Basement.get(*args, &block)
  end

  def self.post(*args, &block)
    Basement.post(*args, &block)
  end

  def self.patch(*args, &block)
    Basement.patch(*args, &block)
  end

  def self.put(*args, &block)
    Basement.put(*args, &block)
  end

  def self.delete(*args, &block)
    Basement.delete(*args, &block)
  end

  def self.move(*args, &block)
    Basement.move(*args, &block)
  end

  def self.copy(*args, &block)
    Basement.copy(*args, &block)
  end

  def self.head(*args, &block)
    Basement.head(*args, &block)
  end

  def self.options(*args, &block)
    Basement.options(*args, &block)
  end
end

require 'httparty/hash_conversions'
require 'httparty/utils'
require 'httparty/exceptions'
require 'httparty/parser'
require 'httparty/request'
require 'httparty/response'
