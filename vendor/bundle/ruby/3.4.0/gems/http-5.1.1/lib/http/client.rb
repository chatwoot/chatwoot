# frozen_string_literal: true

require "forwardable"

require "http/form_data"
require "http/options"
require "http/feature"
require "http/headers"
require "http/connection"
require "http/redirector"
require "http/uri"

module HTTP
  # Clients make requests and receive responses
  class Client
    extend Forwardable
    include Chainable

    HTTP_OR_HTTPS_RE = %r{^https?://}i.freeze

    def initialize(default_options = {})
      @default_options = HTTP::Options.new(default_options)
      @connection = nil
      @state = :clean
    end

    # Make an HTTP request
    def request(verb, uri, opts = {})
      opts = @default_options.merge(opts)
      req = build_request(verb, uri, opts)
      res = perform(req, opts)
      return res unless opts.follow

      Redirector.new(opts.follow).perform(req, res) do |request|
        perform(wrap_request(request, opts), opts)
      end
    end

    # Prepare an HTTP request
    def build_request(verb, uri, opts = {})
      opts    = @default_options.merge(opts)
      uri     = make_request_uri(uri, opts)
      headers = make_request_headers(opts)
      body    = make_request_body(opts, headers)

      req = HTTP::Request.new(
        :verb           => verb,
        :uri            => uri,
        :uri_normalizer => opts.feature(:normalize_uri)&.normalizer,
        :proxy          => opts.proxy,
        :headers        => headers,
        :body           => body
      )

      wrap_request(req, opts)
    end

    # @!method persistent?
    #   @see Options#persistent?
    #   @return [Boolean] whenever client is persistent
    def_delegator :default_options, :persistent?

    # Perform a single (no follow) HTTP request
    def perform(req, options)
      verify_connection!(req.uri)

      @state = :dirty

      begin
        @connection ||= HTTP::Connection.new(req, options)

        unless @connection.failed_proxy_connect?
          @connection.send_request(req)
          @connection.read_headers!
        end
      rescue Error => e
        options.features.each_value do |feature|
          feature.on_error(req, e)
        end
        raise
      end
      res = build_response(req, options)

      res = options.features.inject(res) do |response, (_name, feature)|
        feature.wrap_response(response)
      end

      @connection.finish_response if req.verb == :head
      @state = :clean

      res
    rescue
      close
      raise
    end

    def close
      @connection&.close
      @connection = nil
      @state = :clean
    end

    private

    def wrap_request(req, opts)
      opts.features.inject(req) do |request, (_name, feature)|
        feature.wrap_request(request)
      end
    end

    def build_response(req, options)
      Response.new(
        :status        => @connection.status_code,
        :version       => @connection.http_version,
        :headers       => @connection.headers,
        :proxy_headers => @connection.proxy_response_headers,
        :connection    => @connection,
        :encoding      => options.encoding,
        :request       => req
      )
    end

    # Verify our request isn't going to be made against another URI
    def verify_connection!(uri)
      if default_options.persistent? && uri.origin != default_options.persistent
        raise StateError, "Persistence is enabled for #{default_options.persistent}, but we got #{uri.origin}"
      end

      # We re-create the connection object because we want to let prior requests
      # lazily load the body as long as possible, and this mimics prior functionality.
      return close if @connection && (!@connection.keep_alive? || @connection.expired?)

      # If we get into a bad state (eg, Timeout.timeout ensure being killed)
      # close the connection to prevent potential for mixed responses.
      return close if @state == :dirty
    end

    # Merges query params if needed
    #
    # @param [#to_s] uri
    # @return [URI]
    def make_request_uri(uri, opts)
      uri = uri.to_s

      uri = "#{default_options.persistent}#{uri}" if default_options.persistent? && uri !~ HTTP_OR_HTTPS_RE

      uri = HTTP::URI.parse uri

      uri.query_values = uri.query_values(Array).to_a.concat(opts.params.to_a) if opts.params && !opts.params.empty?

      # Some proxies (seen on WEBRick) fail if URL has
      # empty path (e.g. `http://example.com`) while it's RFC-complaint:
      # http://tools.ietf.org/html/rfc1738#section-3.1
      uri.path = "/" if uri.path.empty?

      uri
    end

    # Creates request headers with cookies (if any) merged in
    def make_request_headers(opts)
      headers = opts.headers

      # Tell the server to keep the conn open
      headers[Headers::CONNECTION] = default_options.persistent? ? Connection::KEEP_ALIVE : Connection::CLOSE

      cookies = opts.cookies.values

      unless cookies.empty?
        cookies = opts.headers.get(Headers::COOKIE).concat(cookies).join("; ")
        headers[Headers::COOKIE] = cookies
      end

      headers
    end

    # Create the request body object to send
    def make_request_body(opts, headers)
      case
      when opts.body
        opts.body
      when opts.form
        form = make_form_data(opts.form)
        headers[Headers::CONTENT_TYPE] ||= form.content_type
        form
      when opts.json
        body = MimeType[:json].encode opts.json
        headers[Headers::CONTENT_TYPE] ||= "application/json; charset=#{body.encoding.name}"
        body
      end
    end

    def make_form_data(form)
      return form if form.is_a? HTTP::FormData::Multipart
      return form if form.is_a? HTTP::FormData::Urlencoded

      HTTP::FormData.create(form)
    end
  end
end
