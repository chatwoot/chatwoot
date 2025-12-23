# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Check that the parameters on a multi-line method call or definition are aligned.
      #
      # To set the alignment of the first argument, use the
      # `Layout/FirstParameterIndentation` cop.
      #
      # @example EnforcedStyle: with_first_parameter (default)
      #   # good
      #
      #   def foo(bar,
      #           baz)
      #     123
      #   end
      #
      #   def foo(
      #     bar,
      #     baz
      #   )
      #     123
      #   end
      #
      #   # bad
      #
      #   def foo(bar,
      #        baz)
      #     123
      #   end
      #
      #   # bad
      #
      #   def foo(
      #     bar,
      #        baz)
      #     123
      #   end
      #
      # @example EnforcedStyle: with_fixed_indentation
      #   # good
      #
      #   def foo(bar,
      #     baz)
      #     123
      #   end
      #
      #   def foo(
      #     bar,
      #     baz
      #   )
      #     123
      #   end
      #
      #   # bad
      #
      #   def foo(bar,
      #           baz)
      #     123
      #   end
      #
      #   # bad
      #
      #   def foo(
      #     bar,
      #        baz)
      #     123
      #   end
      class ParameterAlignment < Base
        include Alignment
        extend AutoCorrector

        ALIGN_PARAMS_MSG = 'Align the parameters of a method definition if ' \
                           'they span more than one line.'

        FIXED_INDENT_MSG = 'Use one level of indentation for parameters ' \
                           'following the first line of a multi-line method definition.'

        def on_def(node)
          return if node.arguments.size < 2

          check_alignment(node.arguments, base_column(node, node.arguments))
        end
        alias on_defs on_def

        private

        def autocorrect(corrector, node)
          AlignmentCorrector.correct(corrector, processed_source, node, column_delta)
        end

        def message(_node)
          fixed_indentation? ? FIXED_INDENT_MSG : ALIGN_PARAMS_MSG
        end

        def fixed_indentation?
          cop_config['EnforcedStyle'] == 'with_fixed_indentation'
        end

        def base_column(node, args)
          if fixed_indentation?
            lineno = target_method_lineno(node)
            line = node.source_range.source_buffer.source_line(lineno)
            indentation_of_line = /\S.*/.match(line).begin(0)
            indentation_of_line + configured_indentation_width
          else
            display_column(args.first.source_range)
          end
        end

        def target_method_lineno(node)
          node.loc.keyword.line
        end
      end
    end
  end
end
