# frozen_string_literal: true

require "set"

require "http/headers"

module HTTP
  class Redirector
    # Notifies that we reached max allowed redirect hops
    class TooManyRedirectsError < ResponseError; end

    # Notifies that following redirects got into an endless loop
    class EndlessRedirectError < TooManyRedirectsError; end

    # HTTP status codes which indicate redirects
    REDIRECT_CODES = [300, 301, 302, 303, 307, 308].to_set.freeze

    # Codes which which should raise StateError in strict mode if original
    # request was any of {UNSAFE_VERBS}
    STRICT_SENSITIVE_CODES = [300, 301, 302].to_set.freeze

    # Insecure http verbs, which should trigger StateError in strict mode
    # upon {STRICT_SENSITIVE_CODES}
    UNSAFE_VERBS = %i[put delete post].to_set.freeze

    # Verbs which will remain unchanged upon See Other response.
    SEE_OTHER_ALLOWED_VERBS = %i[get head].to_set.freeze

    # @!attribute [r] strict
    #   Returns redirector policy.
    #   @return [Boolean]
    attr_reader :strict

    # @!attribute [r] max_hops
    #   Returns maximum allowed hops.
    #   @return [Fixnum]
    attr_reader :max_hops

    # @param [Hash] opts
    # @option opts [Boolean] :strict (true) redirector hops policy
    # @option opts [#to_i] :max_hops (5) maximum allowed amount of hops
    def initialize(opts = {})
      @strict      = opts.fetch(:strict, true)
      @max_hops    = opts.fetch(:max_hops, 5).to_i
      @on_redirect = opts.fetch(:on_redirect, nil)
    end

    # Follows redirects until non-redirect response found
    def perform(request, response)
      @request  = request
      @response = response
      @visited  = []
      collect_cookies_from_request
      collect_cookies_from_response

      while REDIRECT_CODES.include? @response.status.code
        @visited << "#{@request.verb} #{@request.uri}"

        raise TooManyRedirectsError if too_many_hops?
        raise EndlessRedirectError  if endless_loop?

        @response.flush

        # XXX(ixti): using `Array#inject` to return `nil` if no Location header.
        @request = redirect_to(@response.headers.get(Headers::LOCATION).inject(:+))
        unless cookie_jar.empty?
          @request.headers.set(Headers::COOKIE, cookie_jar.cookies.map { |c| "#{c.name}=#{c.value}" }.join("; "))
        end
        @on_redirect.call @response, @request if @on_redirect.respond_to?(:call)
        @response = yield @request
        collect_cookies_from_response
      end

      @response
    end

    private

    # All known cookies. On the original request, this is only the original cookies, but after that,
    # Set-Cookie headers can add, set or delete cookies.
    def cookie_jar
      # it seems that @response.cookies instance is reused between responses, so we have to "clone"
      @cookie_jar ||= HTTP::CookieJar.new
    end

    def collect_cookies_from_request
      request_cookie_header = @request.headers["Cookie"]
      cookies =
        if request_cookie_header
          HTTP::Cookie.cookie_value_to_hash(request_cookie_header)
        else
          {}
        end

      cookies.each do |key, value|
        cookie_jar.add(HTTP::Cookie.new(key, value, :path => @request.uri.path, :domain => @request.host))
      end
    end

    # Carry cookies from one response to the next. Carrying cookies to the next response ends up
    # carrying them to the next request as well.
    #
    # Note that this isn't part of the IETF standard, but all major browsers support setting cookies
    # on redirect: https://blog.dubbelboer.com/2012/11/25/302-cookie.html
    def collect_cookies_from_response
      # Overwrite previous cookies
      @response.cookies.each do |cookie|
        if cookie.value == ""
          cookie_jar.delete(cookie)
        else
          cookie_jar.add(cookie)
        end
      end

      # I wish we could just do @response.cookes = cookie_jar
      cookie_jar.each do |cookie|
        @response.cookies.add(cookie)
      end
    end

    # Check if we reached max amount of redirect hops
    # @return [Boolean]
    def too_many_hops?
      1 <= @max_hops && @max_hops < @visited.count
    end

    # Check if we got into an endless loop
    # @return [Boolean]
    def endless_loop?
      2 <= @visited.count(@visited.last)
    end

    # Redirect policy for follow
    # @return [Request]
    def redirect_to(uri)
      raise StateError, "no Location header in redirect" unless uri

      verb = @request.verb
      code = @response.status.code

      if UNSAFE_VERBS.include?(verb) && STRICT_SENSITIVE_CODES.include?(code)
        raise StateError, "can't follow #{@response.status} redirect" if @strict

        verb = :get
      end

      verb = :get if !SEE_OTHER_ALLOWED_VERBS.include?(verb) && 303 == code

      @request.redirect(uri, verb)
    end
  end
end
