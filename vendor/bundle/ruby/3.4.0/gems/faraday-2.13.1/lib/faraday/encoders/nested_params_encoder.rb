# frozen_string_literal: true

module Faraday
  # Sub-module for encoding parameters into query-string.
  module EncodeMethods
    # @param params [nil, Array, #to_hash] parameters to be encoded
    #
    # @return [String] the encoded params
    #
    # @raise [TypeError] if params can not be converted to a Hash
    def encode(params)
      return nil if params.nil?

      unless params.is_a?(Array)
        unless params.respond_to?(:to_hash)
          raise TypeError, "Can't convert #{params.class} into Hash."
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
      params.each do |parent, value|
        encoded_parent = escape(parent)
        buffer << "#{encode_pair(encoded_parent, value)}&"
      end
      buffer.chop
    end

    protected

    def encode_pair(parent, value)
      if value.is_a?(Hash)
        encode_hash(parent, value)
      elsif value.is_a?(Array)
        encode_array(parent, value)
      elsif value.nil?
        parent
      else
        encoded_value = escape(value)
        "#{parent}=#{encoded_value}"
      end
    end

    def encode_hash(parent, value)
      value = value.map { |key, val| [escape(key), val] }.sort

      buffer = +''
      value.each do |key, val|
        new_parent = "#{parent}%5B#{key}%5D"
        buffer << "#{encode_pair(new_parent, val)}&"
      end
      buffer.chop
    end

    def encode_array(parent, value)
      return "#{parent}%5B%5D" if value.empty?

      buffer = +''
      value.each_with_index do |val, index|
        new_parent = if @array_indices
                       "#{parent}%5B#{index}%5D"
                     else
                       "#{parent}%5B%5D"
                     end
        buffer << "#{encode_pair(new_parent, val)}&"
      end
      buffer.chop
    end
  end

  # Sub-module for decoding query-string into parameters.
  module DecodeMethods
    # @param query [nil, String]
    #
    # @return [Array<Array, String>] the decoded params
    #
    # @raise [TypeError] if the nesting is incorrect
    def decode(query)
      return nil if query.nil?

      params = {}
      query.split('&').each do |pair|
        next if pair.empty?

        key, value = pair.split('=', 2)
        key = unescape(key)
        value = unescape(value.tr('+', ' ')) if value
        decode_pair(key, value, params)
      end

      dehash(params, 0)
    end

    protected

    SUBKEYS_REGEX = /[^\[\]]+(?:\]?\[\])?/

    def decode_pair(key, value, context)
      subkeys = key.scan(SUBKEYS_REGEX)
      subkeys.each_with_index do |subkey, i|
        is_array = subkey =~ /[\[\]]+\Z/
        subkey = Regexp.last_match.pre_match if is_array
        last_subkey = i == subkeys.length - 1

        context = prepare_context(context, subkey, is_array, last_subkey)
        add_to_context(is_array, context, value, subkey) if last_subkey
      end
    end

    def prepare_context(context, subkey, is_array, last_subkey)
      if !last_subkey || is_array
        context = new_context(subkey, is_array, context)
      end
      if context.is_a?(Array) && !is_array
        context = match_context(context, subkey)
      end
      context
    end

    def new_context(subkey, is_array, context)
      value_type = is_array ? Array : Hash
      if context[subkey] && !context[subkey].is_a?(value_type)
        raise TypeError, "expected #{value_type.name} " \
                         "(got #{context[subkey].class.name}) for param `#{subkey}'"
      end

      context[subkey] ||= value_type.new
    end

    def match_context(context, subkey)
      context << {} if !context.last.is_a?(Hash) || context.last.key?(subkey)
      context.last
    end

    def add_to_context(is_array, context, value, subkey)
      is_array ? context << value : context[subkey] = value
    end

    # Internal: convert a nested hash with purely numeric keys into an array.
    # FIXME: this is not compatible with Rack::Utils.parse_nested_query
    # @!visibility private
    def dehash(hash, depth)
      hash.each do |key, value|
        hash[key] = dehash(value, depth + 1) if value.is_a?(Hash)
      end

      if depth.positive? && !hash.empty? && hash.keys.all? { |k| k =~ /^\d+$/ }
        hash.sort.map(&:last)
      else
        hash
      end
    end
  end

  # This is the default encoder for Faraday requests.
  # Using this encoder, parameters will be encoded respecting their structure,
  # so you can send objects such as Arrays or Hashes as parameters
  # for your requests.
  module NestedParamsEncoder
    class << self
      attr_accessor :sort_params, :array_indices

      extend Forwardable
      def_delegators :'Faraday::Utils', :escape, :unescape
    end

    # Useful default for OAuth and caching.
    @sort_params = true
    @array_indices = false

    extend EncodeMethods
    extend DecodeMethods
  end
end
