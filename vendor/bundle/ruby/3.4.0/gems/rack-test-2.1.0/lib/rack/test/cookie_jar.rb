# frozen_string_literal: true

require 'uri'
require 'time'

module Rack
  module Test
    # Represents individual cookies in the cookie jar.  This is considered private
    # API and behavior of this class can change at any time.
    class Cookie # :nodoc:
      include Rack::Utils

      # The name of the cookie, will be a string
      attr_reader :name
      
      # The value of the cookie, will be a string or nil if there is no value.
      attr_reader :value

      # The raw string for the cookie, without options. Will generally be in
      # name=value format is name and value are provided.
      attr_reader :raw

      def initialize(raw, uri = nil, default_host = DEFAULT_HOST)
        @default_host = default_host
        uri ||= default_uri

        # separate the name / value pair from the cookie options
        @raw, options = raw.split(/[;,] */n, 2)

        @name, @value = parse_query(@raw, ';').to_a.first
        @options = parse_query(options, ';')

        if domain = @options['domain']
          @exact_domain_match = false
          domain[0] = '' if domain[0] == '.'
        else
          # If the domain attribute is not present in the cookie,
          # the domain must match exactly.
          @exact_domain_match = true
          @options['domain'] = (uri.host || default_host)
        end

        # Set the path for the cookie to the directory containing
        # the request if it isn't set.
        @options['path'] ||= uri.path.sub(/\/[^\/]*\Z/, '')
      end

      # Wether the given cookie can replace the current cookie in the cookie jar.
      def replaces?(other)
        [name.downcase, domain, path] == [other.name.downcase, other.domain, other.path]
      end

      # Whether the cookie has a value.
      def empty?
        @value.nil? || @value.empty?
      end

      # The explicit or implicit domain for the cookie.
      def domain
        @options['domain']
      end

      # Whether the cookie has the secure flag, indicating it can only be sent over
      # an encrypted connection.
      def secure?
        @options.key?('secure')
      end

      # Whether the cookie has the httponly flag, indicating it is not available via
      # a javascript API.
      def http_only?
        @options.key?('HttpOnly') || @options.key?('httponly')
      end

      # The explicit or implicit path for the cookie.
      def path
        ([*@options['path']].first.split(',').first || '/').strip
      end

      # A Time value for when the cookie expires, if the expires option is set.
      def expires
        Time.parse(@options['expires']) if @options['expires']
      end

      # Whether the cookie is currently expired.
      def expired?
        expires && expires < Time.now
      end

      # Whether the cookie is valid for the given URI.
      def valid?(uri)
        uri ||= default_uri

        uri.host = @default_host if uri.host.nil?

        real_domain = domain =~ /^\./ ? domain[1..-1] : domain
        !!((!secure? || (secure? && uri.scheme == 'https')) &&
          uri.host =~ Regexp.new("#{'^' if @exact_domain_match}#{Regexp.escape(real_domain)}$", Regexp::IGNORECASE))
      end

      # Cookies that do not match the URI will not be sent in requests to the URI.
      def matches?(uri)
        !expired? && valid?(uri) && uri.path.start_with?(path)
      end

      # Order cookies by name, path, and domain.
      def <=>(other)
        [name, path, domain.reverse] <=> [other.name, other.path, other.domain.reverse]
      end

      # A hash of cookie options, including the cookie value, but excluding the cookie name.
      def to_h
        @options.merge(
          'value'    => @value,
          'HttpOnly' => http_only?,
          'secure'   => secure?
        )
      end
      alias to_hash to_h

      private

      # The default URI to use for the cookie, including just the host.
      def default_uri
        URI.parse('//' + @default_host + '/')
      end
    end

    # Represents all cookies for a session, handling adding and
    # removing cookies, and finding which cookies apply to a given
    # request.  This is considered private API and behavior of this
    # class can change at any time.
    class CookieJar # :nodoc:
      DELIMITER = '; '.freeze

      def initialize(cookies = [], default_host = DEFAULT_HOST)
        @default_host = default_host
        @cookies = cookies.sort!
      end

      # Ensure the copy uses a distinct cookies array.
      def initialize_copy(other)
        super
        @cookies = @cookies.dup
      end

      # Return the value for first cookie with the given name, or nil
      # if no such cookie exists.
      def [](name)
        name = name.to_s
        @cookies.each do |cookie|
          return cookie.value if cookie.name == name
        end
        nil
      end

      # Set a cookie with the given name and value in the
      # cookie jar.
      def []=(name, value)
        merge("#{name}=#{Rack::Utils.escape(value)}")
      end

      # Return the first cookie with the given name, or nil if
      # no such cookie exists.
      def get_cookie(name)
        @cookies.each do |cookie|
          return cookie if cookie.name == name
        end
        nil
      end

      # Delete all cookies with the given name from the cookie jar.
      def delete(name)
        @cookies.reject! do |cookie|
          cookie.name == name
        end
        nil
      end

      # Add a string of raw cookie information to the cookie jar,
      # if the cookie is valid for the given URI.
      # Cookies should be separated with a newline.
      def merge(raw_cookies, uri = nil)
        return unless raw_cookies

        if raw_cookies.is_a? String
          raw_cookies = raw_cookies.split("\n")
          raw_cookies.reject!(&:empty?)
        end

        raw_cookies.each do |raw_cookie|
          cookie = Cookie.new(raw_cookie, uri, @default_host)
          self << cookie if cookie.valid?(uri)
        end
      end

      # Add a Cookie to the cookie jar.
      def <<(new_cookie)
        @cookies.reject! do |existing_cookie|
          new_cookie.replaces?(existing_cookie)
        end

        @cookies << new_cookie
        @cookies.sort!
      end

      # Return a raw cookie string for the cookie header to
      # use for the given URI.
      def for(uri)
        buf = String.new
        delimiter = nil

        each_cookie_for(uri) do |cookie|
          if delimiter
            buf << delimiter
          else
            delimiter = DELIMITER
          end
          buf << cookie.raw
        end

        buf
      end

      # Return a hash cookie names and cookie values for cookies in the jar.
      def to_hash
        cookies = {}

        @cookies.each do |cookie|
          cookies[cookie.name] = cookie.value
        end

        cookies
      end

      private

      # Yield each cookie that matches for the URI.
      #
      # The cookies are sorted by most specific first. So, we loop through
      # all the cookies in order and add it to a hash by cookie name if
      # the cookie can be sent to the current URI. It's added to the hash
      # so that when we are done, the cookies will be unique by name and
      # we'll have grabbed the most specific to the URI.
      def each_cookie_for(uri)
        @cookies.each do |cookie|
          yield cookie if !uri || cookie.matches?(uri)
        end
      end
    end
  end
end
