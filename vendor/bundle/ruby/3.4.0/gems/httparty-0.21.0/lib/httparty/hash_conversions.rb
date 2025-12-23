# frozen_string_literal: true

require 'erb'

module HTTParty
  module HashConversions
    # @return <String> This hash as a query string
    #
    # @example
    #   { name: "Bob",
    #     address: {
    #       street: '111 Ruby Ave.',
    #       city: 'Ruby Central',
    #       phones: ['111-111-1111', '222-222-2222']
    #     }
    #   }.to_params
    #     #=> "name=Bob&address[city]=Ruby Central&address[phones][]=111-111-1111&address[phones][]=222-222-2222&address[street]=111 Ruby Ave."
    def self.to_params(hash)
      hash.to_hash.map { |k, v| normalize_param(k, v) }.join.chop
    end

    # @param key<Object> The key for the param.
    # @param value<Object> The value for the param.
    #
    # @return <String> This key value pair as a param
    #
    # @example normalize_param(:name, "Bob Jones") #=> "name=Bob%20Jones&"
    def self.normalize_param(key, value)
      normalized_keys = normalize_keys(key, value)

      normalized_keys.flatten.each_slice(2).inject(''.dup) do |string, (k, v)|
        string << "#{ERB::Util.url_encode(k)}=#{ERB::Util.url_encode(v.to_s)}&"
      end
    end

    def self.normalize_keys(key, value)
      stack = []
      normalized_keys = []

      if value.respond_to?(:to_ary)
        if value.empty?
          normalized_keys << ["#{key}[]", '']
        else
          normalized_keys = value.to_ary.flat_map do |element|
            normalize_keys("#{key}[]", element)
          end
        end
      elsif value.respond_to?(:to_hash)
        stack << [key, value.to_hash]
      else
        normalized_keys << [key.to_s, value]
      end

      stack.each do |parent, hash|
        hash.each do |child_key, child_value|
          if child_value.respond_to?(:to_hash)
            stack << ["#{parent}[#{child_key}]", child_value.to_hash]
          elsif child_value.respond_to?(:to_ary)
            child_value.to_ary.each do |v|
              normalized_keys << normalize_keys("#{parent}[#{child_key}][]", v).flatten
            end
          else
            normalized_keys << normalize_keys("#{parent}[#{child_key}]", child_value).flatten
          end
        end
      end

      normalized_keys
    end
  end
end
