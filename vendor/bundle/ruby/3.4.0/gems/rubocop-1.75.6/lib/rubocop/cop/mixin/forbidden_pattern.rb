# frozen_string_literal: true

module RuboCop
  module Cop
    # This module encapsulates the ability to forbid certain patterns in a cop.
    module ForbiddenPattern
      def forbidden_pattern?(name)
        forbidden_patterns.any? { |pattern| Regexp.new(pattern).match?(name) }
      end

      def forbidden_patterns
        cop_config.fetch('ForbiddenPatterns', [])
      end
    end
  end
end
