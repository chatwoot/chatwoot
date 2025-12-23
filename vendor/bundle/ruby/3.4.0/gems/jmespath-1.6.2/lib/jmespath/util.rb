# frozen_string_literal: true
module JMESPath
  # @api private
  module Util
    class << self
      # Determines if a value is false as defined by JMESPath:
      #
      #   https://github.com/jmespath/jmespath.site/blob/master/docs/proposals/improved-filters.rst#and-expressions-1
      #
      def falsey?(value)
        !value ||
          (value.respond_to?(:to_ary) && value.to_ary.empty?) ||
          (value.respond_to?(:to_hash) && value.to_hash.empty?) ||
          (value.respond_to?(:to_str) && value.to_str.empty?) ||
          (value.respond_to?(:entries) && !value.entries.any?)
        # final case necessary to support Enumerable and Struct
      end

      def as_json(value)
        if value.respond_to?(:to_ary)
          value.to_ary.map { |e| as_json(e) }
        elsif value.respond_to?(:to_hash)
          hash = {}
          value.to_hash.each_pair { |k, v| hash[k] = as_json(v) }
          hash
        elsif value.respond_to?(:to_str)
          value.to_str
        else
          value
        end
      end
    end
  end
end
