# frozen_string_literal: true

module Faraday
  # FlatParamsEncoder manages URI params as a flat hash. Any Array values repeat
  # the parameter multiple times.
  module FlatParamsEncoder
    class << self
      extend Forwardable
      def_delegators :'Faraday::Utils', :escape, :unescape
    end

    # Encode converts the given param into a URI querystring. Keys and values
    # will converted to strings and appropriately escaped for the URI.
    #
    # @param params [Hash] query arguments to convert.
    #
    # @example
    #
    #   encode({a: %w[one two three], b: true, c: "C"})
    #   # => 'a=one&a=two&a=three&b=true&c=C'
    #
    # @return [String] the URI querystring (without the leading '?')
    def self.encode(params)
      return nil if params.nil?

      unless params.is_a?(Array)
        unless params.respond_to?(:to_hash)
          raise TypeError,
                "Can't convert #{params.class} into Hash."
        end
        params = params.to_hash
        params = params.map do |key, value|
          key = key.to_s if key.is_a?(Symbol)
          [key, value]
        end

        # Only to be used for non-Array inputs. Arrays should preserve order.
        params.sort! if @sort_params
      end

      # The params have form [['key1', 'value1'], ['key2', 'value2']].
      buffer = +''
      params.each do |key, value|
        encoded_key = escape(key)
        if value.nil?
          buffer << "#{encoded_key}&"
        elsif value.is_a?(Array)
          if value.empty?
            buffer << "#{encoded_key}=&"
          else
            value.each do |sub_value|
              encoded_value = escape(sub_value)
              buffer << "#{encoded_key}=#{encoded_value}&"
            end
          end
        else
          encoded_value = escape(value)
          buffer << "#{encoded_key}=#{encoded_value}&"
        end
      end
      buffer.chop
    end

    # Decode converts the given URI querystring into a hash.
    #
    # @param query [String] query arguments to parse.
    #
    # @example
    #
    #   decode('a=one&a=two&a=three&b=true&c=C')
    #   # => {"a"=>["one", "two", "three"], "b"=>"true", "c"=>"C"}
    #
    # @return [Hash] parsed keys and value strings from the querystring.
    def self.decode(query)
      return nil if query.nil?

      empty_accumulator = {}

      split_query = (query.split('&').map do |pair|
        pair.split('=', 2) if pair && !pair.empty?
      end).compact
      split_query.each_with_object(empty_accumulator.dup) do |pair, accu|
        pair[0] = unescape(pair[0])
        pair[1] = true if pair[1].nil?
        if pair[1].respond_to?(:to_str)
          pair[1] = unescape(pair[1].to_str.tr('+', ' '))
        end
        if accu[pair[0]].is_a?(Array)
          accu[pair[0]] << pair[1]
        elsif accu[pair[0]]
          accu[pair[0]] = [accu[pair[0]], pair[1]]
        else
          accu[pair[0]] = pair[1]
        end
      end
    end

    class << self
      attr_accessor :sort_params
    end

    # Useful default for OAuth and caching.
    @sort_params = true
  end
end
