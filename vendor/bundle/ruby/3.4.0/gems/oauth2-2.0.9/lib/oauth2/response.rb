# frozen_string_literal: true

require 'json'
require 'multi_xml'
require 'rack'

module OAuth2
  # OAuth2::Response class
  class Response
    DEFAULT_OPTIONS = {
      parse: :automatic,
      snaky: true,
    }.freeze
    attr_reader :response
    attr_accessor :options

    # Procs that, when called, will parse a response body according
    # to the specified format.
    @@parsers = {
      query: ->(body) { Rack::Utils.parse_query(body) },
      text: ->(body) { body },
    }

    # Content type assignments for various potential HTTP content types.
    @@content_types = {
      'application/x-www-form-urlencoded' => :query,
      'text/plain' => :text,
    }

    # Adds a new content type parser.
    #
    # @param [Symbol] key A descriptive symbol key such as :json or :query.
    # @param [Array] mime_types One or more mime types to which this parser applies.
    # @yield [String] A block returning parsed content.
    def self.register_parser(key, mime_types, &block)
      key = key.to_sym
      @@parsers[key] = block
      Array(mime_types).each do |mime_type|
        @@content_types[mime_type] = key
      end
    end

    # Initializes a Response instance
    #
    # @param [Faraday::Response] response The Faraday response instance
    # @param [Symbol] parse (:automatic) how to parse the response body.  one of :query (for x-www-form-urlencoded),
    #   :json, or :automatic (determined by Content-Type response header)
    # @param [true, false] snaky (true) Convert @parsed to a snake-case,
    #   indifferent-access SnakyHash::StringKeyed, which is a subclass of Hashie::Mash (from hashie gem)?
    # @param [Hash] options all other options for initializing the instance
    def initialize(response, parse: :automatic, snaky: true, **options)
      @response = response
      @options = {
        parse: parse,
        snaky: snaky,
      }.merge(options)
    end

    # The HTTP response headers
    def headers
      response.headers
    end

    # The HTTP response status code
    def status
      response.status
    end

    # The HTTP response body
    def body
      response.body || ''
    end

    # The {#response} {#body} as parsed by {#parser}.
    #
    # @return [Object] As returned by {#parser} if it is #call-able.
    # @return [nil] If the {#parser} is not #call-able.
    def parsed
      return @parsed if defined?(@parsed)

      @parsed =
        if parser.respond_to?(:call)
          case parser.arity
          when 0
            parser.call
          when 1
            parser.call(body)
          else
            parser.call(body, response)
          end
        end

      @parsed = SnakyHash::StringKeyed.new(@parsed) if options[:snaky] && @parsed.is_a?(Hash)

      @parsed
    end

    # Attempts to determine the content type of the response.
    def content_type
      return nil unless response.headers

      ((response.headers.values_at('content-type', 'Content-Type').compact.first || '').split(';').first || '').strip.downcase
    end

    # Determines the parser (a Proc or other Object which responds to #call)
    # that will be passed the {#body} (and optional {#response}) to supply
    # {#parsed}.
    #
    # The parser can be supplied as the +:parse+ option in the form of a Proc
    # (or other Object responding to #call) or a Symbol. In the latter case,
    # the actual parser will be looked up in {@@parsers} by the supplied Symbol.
    #
    # If no +:parse+ option is supplied, the lookup Symbol will be determined
    # by looking up {#content_type} in {@@content_types}.
    #
    # If {#parser} is a Proc, it will be called with no arguments, just
    # {#body}, or {#body} and {#response}, depending on the Proc's arity.
    #
    # @return [Proc, #call] If a parser was found.
    # @return [nil] If no parser was found.
    def parser
      return @parser if defined?(@parser)

      @parser =
        if options[:parse].respond_to?(:call)
          options[:parse]
        elsif options[:parse]
          @@parsers[options[:parse].to_sym]
        end

      @parser ||= @@parsers[@@content_types[content_type]]
    end
  end
end

OAuth2::Response.register_parser(:xml, ['text/xml', 'application/rss+xml', 'application/rdf+xml', 'application/atom+xml', 'application/xml']) do |body|
  next body unless body.respond_to?(:to_str)

  MultiXml.parse(body)
end

OAuth2::Response.register_parser(:json, ['application/json', 'text/javascript', 'application/hal+json', 'application/vnd.collection+json', 'application/vnd.api+json', 'application/problem+json']) do |body|
  next body unless body.respond_to?(:to_str)

  body = body.dup.force_encoding(::Encoding::ASCII_8BIT) if body.respond_to?(:force_encoding)

  ::JSON.parse(body)
end
