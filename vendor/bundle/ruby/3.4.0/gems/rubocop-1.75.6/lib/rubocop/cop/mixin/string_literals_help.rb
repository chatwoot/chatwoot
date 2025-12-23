# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for cops checking single/double quotes.
    module StringLiteralsHelp
      private

      def wrong_quotes?(src_or_node)
        src = src_or_node.is_a?(RuboCop::AST::Node) ? src_or_node.source : src_or_node
        return false if src.start_with?('%', '?')

        if style == :single_quotes
          !double_quotes_required?(src)
        else
          !/" | \\[^'\\] | \#[@{$]/x.match?(src)
        end
      end

      def preferred_string_literal
        enforce_double_quotes? ? '""' : "''"
      end

      def enforce_double_quotes?
        string_literals_config['EnforcedStyle'] == 'double_quotes'
      end

      def string_literals_config
        config.for_enabled_cop('Style/StringLiterals')
      end
    end
  end
end
