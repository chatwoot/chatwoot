# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks expressions wrapping styles for multiline memoization.
      #
      # @example EnforcedStyle: keyword (default)
      #   # bad
      #   foo ||= (
      #     bar
      #     baz
      #   )
      #
      #   # good
      #   foo ||= begin
      #     bar
      #     baz
      #   end
      #
      # @example EnforcedStyle: braces
      #   # bad
      #   foo ||= begin
      #     bar
      #     baz
      #   end
      #
      #   # good
      #   foo ||= (
      #     bar
      #     baz
      #   )
      class MultilineMemoization < Base
        include Alignment
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        KEYWORD_MSG = 'Wrap multiline memoization blocks in `begin` and `end`.'
        BRACES_MSG = 'Wrap multiline memoization blocks in `(` and `)`.'

        def on_or_asgn(node)
          rhs = node.expression

          return unless bad_rhs?(rhs)

          add_offense(node) do |corrector|
            if style == :keyword
              keyword_autocorrect(rhs, corrector)
            else
              corrector.replace(rhs.loc.begin, '(')
              corrector.replace(rhs.loc.end, ')')
            end
          end
        end

        def message(_node)
          style == :braces ? BRACES_MSG : KEYWORD_MSG
        end

        private

        def bad_rhs?(rhs)
          return false unless rhs.multiline?

          if style == :keyword
            rhs.begin_type?
          else
            rhs.kwbegin_type?
          end
        end

        def keyword_autocorrect(node, corrector)
          node_buf = node.source_range.source_buffer
          corrector.replace(node.loc.begin, keyword_begin_str(node, node_buf))
          corrector.replace(node.loc.end, keyword_end_str(node, node_buf))
        end

        def keyword_begin_str(node, node_buf)
          if node_buf.source[node.loc.begin.end_pos] == "\n"
            'begin'
          else
            "begin\n#{' ' * (node.loc.column + configured_indentation_width)}"
          end
        end

        def keyword_end_str(node, node_buf)
          if /[^\s)]/.match?(node_buf.source_line(node.loc.end.line))
            "\n#{' ' * node.loc.column}end"
          else
            'end'
          end
        end
      end
    end
  end
end
