# frozen_string_literal: true

require "em-http"
require "oauth/helper"
require "oauth/request_proxy/em_http_request"

# Extensions for em-http so that we can use consumer.sign! with an EventMachine::HttpClient
# instance. This is purely syntactic sugar.
module EventMachine
  class HttpClient
    attr_reader :oauth_helper

    # Add the OAuth information to an HTTP request. Depending on the <tt>options[:scheme]</tt> setting
    # this may add a header, additional query string parameters, or additional POST body parameters.
    # The default scheme is +header+, in which the OAuth parameters as put into the +Authorization+
    # header.
    #
    # * http - Configured Net::HTTP instance, ignored in this scenario except for getting host.
    # * consumer - OAuth::Consumer instance
    # * token - OAuth::Token instance
    # * options - Request-specific options (e.g. +request_uri+, +consumer+, +token+, +scheme+,
    #   +signature_method+, +nonce+, +timestamp+)
    #
    # This method also modifies the <tt>User-Agent</tt> header to add the OAuth gem version.
    #
    # See Also: {OAuth core spec version 1.0, section 5.4.1}[http://oauth.net/core/1.0#rfc.section.5.4.1]
    def oauth!(http, consumer = nil, token = nil, options = {})
      options = { request_uri: normalized_oauth_uri(http),
                  consumer: consumer,
                  token: token,
                  scheme: "header",
                  signature_method: nil,
                  nonce: nil,
                  timestamp: nil }.merge(options)

      @oauth_helper = OAuth::Client::Helper.new(self, options)
      __send__(:"set_oauth_#{options[:scheme]}")
    end

    # Create a string suitable for signing for an HTTP request. This process involves parameter
    # normalization as specified in the OAuth specification. The exact normalization also depends
    # on the <tt>options[:scheme]</tt> being used so this must match what will be used for the request
    # itself. The default scheme is +header+, in which the OAuth parameters as put into the +Authorization+
    # header.
    #
    # * http - Configured Net::HTTP instance
    # * consumer - OAuth::Consumer instance
    # * token - OAuth::Token instance
    # * options - Request-specific options (e.g. +request_uri+, +consumer+, +token+, +scheme+,
    #   +signature_method+, +nonce+, +timestamp+)
    #
    # See Also: {OAuth core spec version 1.0, section 9.1.1}[http://oauth.net/core/1.0#rfc.section.9.1.1]
    def signature_base_string(http, consumer = nil, token = nil, options = {})
      options = { request_uri: normalized_oauth_uri(http),
                  consumer: consumer,
                  token: token,
                  scheme: "header",
                  signature_method: nil,
                  nonce: nil,
                  timestamp: nil }.merge(options)

      OAuth::Client::Helper.new(self, options).signature_base_string
    end

    # This code was lifted from the em-http-request because it was removed from
    # the gem June 19, 2010
    # see: http://github.com/igrigorik/em-http-request/commit/d536fc17d56dbe55c487eab01e2ff9382a62598b
    def normalize_uri
      @normalized_uri ||= begin
        uri = @conn.dup
        encoded_query = encode_query(@conn, @req[:query])
        path, query = encoded_query.split("?", 2)
        uri.query = query unless encoded_query.empty?
        uri.path  = path
        uri
      end
    end

    protected

    def combine_query(path, query, uri_query)
      combined_query = if query.is_a?(Hash)
                         query.map { |k, v| encode_param(k, v) }.join("&")
                       else
                         query.to_s
                       end
      combined_query = [combined_query, uri_query].reject(&:empty?).join("&") unless uri_query.to_s.empty?
      combined_query.to_s.empty? ? path : "#{path}?#{combined_query}"
    end

    # Since we expect to get the host etc details from the http instance (...),
    # we create a fake url here. Surely this is a horrible, horrible idea?
    def normalized_oauth_uri(http)
      uri = URI.parse(normalize_uri.path)
      uri.host = http.address
      uri.port = http.port

      uri.scheme = if http.respond_to?(:use_ssl?) && http.use_ssl?
                     "https"
                   else
                     "http"
                   end
      uri.to_s
    end

    def set_oauth_header
      req[:head] ||= {}
      req[:head].merge!("Authorization" => @oauth_helper.header)
    end

    def set_oauth_body
      raise NotImplementedError, "please use the set_oauth_header method instead"
    end

    def set_oauth_query_string
      raise NotImplementedError, "please use the set_oauth_header method instead"
    end
  end
end
