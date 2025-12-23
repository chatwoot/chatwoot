# frozen_string_literal: true

# The nested structure that takes nested hashes with indifferent access
#
module Dry
  module Initializer
    class Struct
      extend ::Dry::Initializer

      class << self
        undef_method :param

        def new(options)
          super(**Hash(options).each_with_object({}) { |(k, v), h| h[k.to_sym] = v })
        end
        alias_method :call, :new
      end

      #
      # Represents event data as a nested hash with deeply stringified keys
      # @return [Hash<String, ...>]
      #
      def to_h
        self
          .class
          .dry_initializer
          .attributes(self)
          .each_with_object({}) { |(k, v), h| h[k.to_s] = __hashify(v) }
      end

      private

      def __hashify(value)
        case value
        when Hash
          value.each_with_object({}) { |(k, v), obj| obj[k.to_s] = __hashify(v) }
        when Array then value.map { |v| __hashify(v) }
        when Dry::Initializer::Struct then value.to_h
        else value
        end
      end
    end
  end
end
