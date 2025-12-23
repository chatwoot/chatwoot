# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Check that the arguments on a multi-line method call are aligned.
      #
      # @example EnforcedStyle: with_first_argument (default)
      #   # good
      #
      #   foo :bar,
      #       :baz,
      #       key: value
      #
      #   foo(
      #     :bar,
      #     :baz,
      #     key: value
      #   )
      #
      #   # bad
      #
      #   foo :bar,
      #     :baz,
      #     key: value
      #
      #   foo(
      #     :bar,
      #       :baz,
      #       key: value
      #   )
      #
      # @example EnforcedStyle: with_fixed_indentation
      #   # good
      #
      #   foo :bar,
      #     :baz,
      #     key: value
      #
      #   # bad
      #
      #   foo :bar,
      #       :baz,
      #       key: value
      class ArgumentAlignment < Base
        include Alignment
        extend AutoCorrector

        ALIGN_PARAMS_MSG = 'Align the arguments of a method call if they span more than one line.'

        FIXED_INDENT_MSG = 'Use one level of indentation for arguments ' \
                           'following the first line of a multi-line method call.'

        def on_send(node)
          return if !multiple_arguments?(node) || (node.send_type? && node.method?(:[]=)) ||
                    autocorrect_incompatible_with_other_cops?

          items = flattened_arguments(node)

          check_alignment(items, base_column(node, items.first))
        end

        alias on_csend on_send

        private

        def autocorrect_incompatible_with_other_cops?
          with_first_argument_style? && enforce_hash_argument_with_separator?
        end

        def flattened_arguments(node)
          if fixed_indentation?
            arguments_with_last_arg_pairs(node)
          else
            arguments_or_first_arg_pairs(node)
          end
        end

        def arguments_with_last_arg_pairs(node)
          items = node.arguments[0..-2]
          last_arg = node.last_argument

          if last_arg.hash_type? && !last_arg.braces?
            items += last_arg.pairs
          else
            items << last_arg
          end
          items
        end

        def arguments_or_first_arg_pairs(node)
          first_arg = node.first_argument
          if first_arg.hash_type? && !first_arg.braces?
            first_arg.pairs
          else
            node.arguments
          end
        end

        def multiple_arguments?(node)
          return true if node.arguments.size >= 2

          first_argument = node.first_argument
          first_argument&.hash_type? && first_argument.pairs.count >= 2
        end

        def autocorrect(corrector, node)
          AlignmentCorrector.correct(corrector, processed_source, node, column_delta)
        end

        def message(_node)
          fixed_indentation? ? FIXED_INDENT_MSG : ALIGN_PARAMS_MSG
        end

        def fixed_indentation?
          cop_config['EnforcedStyle'] == 'with_fixed_indentation'
        end

        def with_first_argument_style?
          cop_config['EnforcedStyle'] == 'with_first_argument'
        end

        def base_column(node, first_argument)
          if fixed_indentation? || first_argument.nil?
            lineno = target_method_lineno(node)
            line = node.source_range.source_buffer.source_line(lineno)
            indentation_of_line = /\S.*/.match(line).begin(0)
            indentation_of_line + configured_indentation_width
          else
            display_column(first_argument.source_range)
          end
        end

        def target_method_lineno(node)
          if node.loc.selector
            node.loc.selector.line
          else
            # l.(1) has no selector, so we use the opening parenthesis instead
            node.loc.begin.line
          end
        end

        def enforce_hash_argument_with_separator?
          RuboCop::Cop::Layout::HashAlignment::SEPARATOR_ALIGNMENT_STYLES.any? do |style|
            config.for_enabled_cop('Layout/HashAlignment')[style]&.include?('separator')
          end
        end
      end
    end
  end
end
