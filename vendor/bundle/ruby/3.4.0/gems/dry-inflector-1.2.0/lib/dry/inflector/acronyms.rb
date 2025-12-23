# frozen_string_literal: true

module Dry
  class Inflector
    # A set of acronyms
    #
    # @since 0.1.2
    # @api private
    class Acronyms
      attr_reader :regex

      # @since 0.1.2
      # @api private
      def initialize
        @rules = {}
        define_regex_patterns
      end

      # @since 0.1.2
      # @api private
      def apply_to(word, capitalize: true)
        @rules[word.downcase] || (capitalize ? word.capitalize : word)
      end

      # @since 0.1.2
      # @api private
      def add(rule, replacement)
        @rules[rule] = replacement
        define_regex_patterns
      end

      private

      # @since 0.1.2
      # @api private
      def define_regex_patterns
        regex = @rules.empty? ? /(?=a)b/ : /#{@rules.values.join("|")}/
        @regex = /(?:(?<=([A-Za-z\d]))|\b)(#{regex})(?=\b|[^a-z])/
      end
    end
  end
end
