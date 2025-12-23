# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces using `//` or `%r` around regular expressions.
      #
      # NOTE: The following `%r` cases using a regexp starts with a blank or `=`
      # as a method argument allowed to prevent syntax errors.
      #
      # [source,ruby]
      # ----
      # do_something %r{ regexp} # `do_something / regexp/` is an invalid syntax.
      # do_something %r{=regexp} # `do_something /=regexp/` is an invalid syntax.
      # ----
      #
      # @example EnforcedStyle: slashes (default)
      #   # bad
      #   snake_case = %r{^[\dA-Z_]+$}
      #
      #   # bad
      #   regex = %r{
      #     foo
      #     (bar)
      #     (baz)
      #   }x
      #
      #   # good
      #   snake_case = /^[\dA-Z_]+$/
      #
      #   # good
      #   regex = /
      #     foo
      #     (bar)
      #     (baz)
      #   /x
      #
      # @example EnforcedStyle: percent_r
      #   # bad
      #   snake_case = /^[\dA-Z_]+$/
      #
      #   # bad
      #   regex = /
      #     foo
      #     (bar)
      #     (baz)
      #   /x
      #
      #   # good
      #   snake_case = %r{^[\dA-Z_]+$}
      #
      #   # good
      #   regex = %r{
      #     foo
      #     (bar)
      #     (baz)
      #   }x
      #
      # @example EnforcedStyle: mixed
      #   # bad
      #   snake_case = %r{^[\dA-Z_]+$}
      #
      #   # bad
      #   regex = /
      #     foo
      #     (bar)
      #     (baz)
      #   /x
      #
      #   # good
      #   snake_case = /^[\dA-Z_]+$/
      #
      #   # good
      #   regex = %r{
      #     foo
      #     (bar)
      #     (baz)
      #   }x
      #
      # @example AllowInnerSlashes: false (default)
      #   # If `false`, the cop will always recommend using `%r` if one or more
      #   # slashes are found in the regexp string.
      #
      #   # bad
      #   x =~ /home\//
      #
      #   # good
      #   x =~ %r{home/}
      #
      # @example AllowInnerSlashes: true
      #   # good
      #   x =~ /home\//
      class RegexpLiteral < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG_USE_SLASHES = 'Use `//` around regular expression.'
        MSG_USE_PERCENT_R = 'Use `%r` around regular expression.'

        def on_regexp(node)
          message = if slash_literal?(node)
                      MSG_USE_PERCENT_R unless allowed_slash_literal?(node)
                    else
                      MSG_USE_SLASHES unless allowed_percent_r_literal?(node)
                    end

          return unless message

          add_offense(node, message: message) do |corrector|
            correct_delimiters(node, corrector)
            correct_inner_slashes(node, corrector)
          end
        end

        private

        def allowed_slash_literal?(node)
          (style == :slashes && !contains_disallowed_slash?(node)) || allowed_mixed_slash?(node)
        end

        def allowed_mixed_slash?(node)
          style == :mixed && node.single_line? && !contains_disallowed_slash?(node)
        end

        def allowed_percent_r_literal?(node)
          (style == :slashes && contains_disallowed_slash?(node)) ||
            style == :percent_r ||
            allowed_mixed_percent_r?(node) || allowed_omit_parentheses_with_percent_r_literal?(node)
        end

        def allowed_mixed_percent_r?(node)
          (style == :mixed && node.multiline?) || contains_disallowed_slash?(node)
        end

        def contains_disallowed_slash?(node)
          !allow_inner_slashes? && contains_slash?(node)
        end

        def contains_slash?(node)
          node_body(node).include?('/')
        end

        def allow_inner_slashes?
          cop_config['AllowInnerSlashes']
        end

        def node_body(node, include_begin_nodes: false)
          types = include_begin_nodes ? %i[str begin] : %i[str]
          node.each_child_node(*types).map(&:source).join
        end

        def slash_literal?(node)
          node.loc.begin.source == '/'
        end

        def preferred_delimiters
          config.for_cop('Style/PercentLiteralDelimiters') ['PreferredDelimiters']['%r'].chars
        end

        def allowed_omit_parentheses_with_percent_r_literal?(node)
          return false unless node.parent&.call_type?
          return true if node.content.start_with?(' ', '=')

          enforced_style = config.for_cop('Style/MethodCallWithArgsParentheses')['EnforcedStyle']

          enforced_style == 'omit_parentheses'
        end

        def correct_delimiters(node, corrector)
          replacement = calculate_replacement(node)
          corrector.replace(node.loc.begin, replacement.first)
          corrector.replace(node.loc.end, replacement.last)
        end

        def correct_inner_slashes(node, corrector)
          regexp_begin = node.loc.begin.end_pos

          inner_slash_indices(node).each do |index|
            start = regexp_begin + index

            corrector.replace(
              range_between(
                start,
                start + inner_slash_before_correction(node).length
              ),
              inner_slash_after_correction(node)
            )
          end
        end

        def inner_slash_indices(node)
          text    = node_body(node, include_begin_nodes: true)
          pattern = inner_slash_before_correction(node)
          index   = -1
          indices = []

          while (index = text.index(pattern, index + 1))
            indices << index
          end

          indices
        end

        def inner_slash_before_correction(node)
          inner_slash_for(node.loc.begin.source)
        end

        def inner_slash_after_correction(node)
          inner_slash_for(calculate_replacement(node).first)
        end

        def inner_slash_for(opening_delimiter)
          if ['/', '%r/'].include?(opening_delimiter)
            '\/'
          else
            '/'
          end
        end

        def calculate_replacement(node)
          if slash_literal?(node)
            ['%r', ''].zip(preferred_delimiters).map(&:join)
          else
            %w[/ /]
          end
        end
      end
    end
  end
end
