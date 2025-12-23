# frozen_string_literal: true

module Dry
  class Inflector
    # A set of inflection rules
    #
    # @since 0.1.0
    # @api private
    class Rules
      # @since 0.1.0
      # @api private
      def initialize
        @rules = []
      end

      # @since 0.1.0
      # @api private
      def apply_to(word)
        result = word.dup
        each { |rule, replacement| break if result.gsub!(rule, replacement) }
        result
      end

      # @since 0.1.0
      # @api private
      def insert(index, array)
        @rules.insert(index, array)
      end

      # @since 0.1.0
      # @api private
      def each(&)
        @rules.each(&)
      end
    end
  end
end
