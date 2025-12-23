# frozen_string_literal: true

require 'uri'
require 'faraday/utils/headers'
require 'faraday/utils/params_hash'

module Faraday
  # Utils contains various static helper methods.
  module Utils
    module_function

    def build_query(params)
      FlatParamsEncoder.encode(params)
    end

    def build_nested_query(params)
      NestedParamsEncoder.encode(params)
    end

    def default_space_encoding
      @default_space_encoding ||= '+'
    end

    class << self
      attr_writer :default_space_encoding
    end

    ESCAPE_RE = /[^a-zA-Z0-9 .~_-]/

    def escape(str)
      str.to_s.gsub(ESCAPE_RE) do |match|
        "%#{match.unpack('H2' * match.bytesize).join('%').upcase}"
      end.gsub(' ', default_space_encoding)
    end

    def unescape(str)
      CGI.unescape str.to_s
    end

    DEFAULT_SEP = /[&;] */n

    # Adapted from Rack
    def parse_query(query)
      FlatParamsEncoder.decode(query)
    end

    def parse_nested_query(query)
      NestedParamsEncoder.decode(query)
    end

    def default_params_encoder
      @default_params_encoder ||= NestedParamsEncoder
    end

    def basic_header_from(login, pass)
      value = ["#{login}:#{pass}"].pack('m') # Base64 encoding
      value.delete!("\n")
      "Basic #{value}"
    end

    class << self
      attr_writer :default_params_encoder
    end

    # Normalize URI() behavior across Ruby versions
    #
    # url - A String or URI.
    #
    # Returns a parsed URI.
    def URI(url) # rubocop:disable Naming/MethodName
      if url.respond_to?(:host)
        url
      elsif url.respond_to?(:to_str)
        default_uri_parser.call(url)
      else
        raise ArgumentError, 'bad argument (expected URI object or URI string)'
      end
    end

    def default_uri_parser
      @default_uri_parser ||= Kernel.method(:URI)
    end

    def default_uri_parser=(parser)
      @default_uri_parser = if parser.respond_to?(:call) || parser.nil?
                              parser
                            else
                              parser.method(:parse)
                            end
    end

    # Receives a String or URI and returns just
    # the path with the query string sorted.
    def normalize_path(url)
      url = URI(url)
      (url.path.start_with?('/') ? url.path : "/#{url.path}") +
        (url.query ? "?#{sort_query_params(url.query)}" : '')
    end

    # Recursive hash update
    def deep_merge!(target, hash)
      hash.each do |key, value|
        target[key] = if value.is_a?(Hash) && (target[key].is_a?(Hash) || target[key].is_a?(Options))
                        deep_merge(target[key], value)
                      else
                        value
                      end
      end
      target
    end

    # Recursive hash merge
    def deep_merge(source, hash)
      deep_merge!(source.dup, hash)
    end

    def sort_query_params(query)
      query.split('&').sort.join('&')
    end
  end
end
