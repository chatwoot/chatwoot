# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      class MethodCallWithArgsParentheses
        # Style omit_parentheses
        # rubocop:disable Metrics/ModuleLength, Metrics/CyclomaticComplexity
        module OmitParentheses
          include RangeHelp

          TRAILING_WHITESPACE_REGEX = /\s+\Z/.freeze
          OMIT_MSG = 'Omit parentheses for method calls with arguments.'
          private_constant :OMIT_MSG

          private

          def omit_parentheses(node) # rubocop:disable Metrics/PerceivedComplexity
            return unless node.parenthesized?
            return if inside_endless_method_def?(node)
            return if require_parentheses_for_hash_value_omission?(node)
            return if syntax_like_method_call?(node)
            return if method_call_before_constant_resolution?(node)
            return if super_call_without_arguments?(node)
            return if legitimate_call_with_parentheses?(node)
            return if allowed_camel_case_method_call?(node)
            return if allowed_string_interpolation_method_call?(node)

            add_offense(offense_range(node), message: OMIT_MSG) do |corrector|
              autocorrect(corrector, node)
            end
          end

          def autocorrect(corrector, node)
            range = args_begin(node)
            if parentheses_at_the_end_of_multiline_call?(node)
              # Whitespace after line continuation (`\ `) is a syntax error
              with_whitespace = range_with_surrounding_space(range, side: :right, newlines: false)
              corrector.replace(with_whitespace, ' \\')
            else
              corrector.replace(range, ' ')
            end
            corrector.remove(node.loc.end)
          end

          def offense_range(node)
            node.loc.begin.join(node.loc.end)
          end

          def inside_endless_method_def?(node)
            # parens are required around arguments inside an endless method
            node.each_ancestor(:any_def).any?(&:endless?) && node.arguments.any?
          end

          def require_parentheses_for_hash_value_omission?(node) # rubocop:disable Metrics/PerceivedComplexity
            return false unless (last_argument = node.last_argument)
            return false if !last_argument.hash_type? || !last_argument.pairs.last&.value_omission?

            node.parent&.conditional? || node.parent&.single_line? || !last_expression?(node)
          end

          # Require hash value omission be enclosed in parentheses to prevent the following issue:
          # https://bugs.ruby-lang.org/issues/18396.
          def last_expression?(node)
            !(node.parent&.assignment? ? node.parent.right_sibling : node.right_sibling)
          end

          def syntax_like_method_call?(node)
            node.implicit_call? || node.operator_method?
          end

          def method_call_before_constant_resolution?(node)
            node.parent&.const_type?
          end

          def super_call_without_arguments?(node)
            node.super_type? && node.arguments.none?
          end

          def allowed_camel_case_method_call?(node)
            node.camel_case_method? &&
              (node.arguments.none? || cop_config['AllowParenthesesInCamelCaseMethod'])
          end

          def allowed_string_interpolation_method_call?(node)
            cop_config['AllowParenthesesInStringInterpolation'] &&
              inside_string_interpolation?(node)
          end

          def parentheses_at_the_end_of_multiline_call?(node)
            node.multiline? &&
              node.loc.begin.source_line
                  .gsub(TRAILING_WHITESPACE_REGEX, '')
                  .end_with?('(')
          end

          def legitimate_call_with_parentheses?(node) # rubocop:disable Metrics/PerceivedComplexity
            call_in_literals?(node) ||
              node.parent&.when_type? ||
              call_with_ambiguous_arguments?(node) ||
              call_in_logical_operators?(node) ||
              call_in_optional_arguments?(node) ||
              call_in_single_line_inheritance?(node) ||
              allowed_multiline_call_with_parentheses?(node) ||
              allowed_chained_call_with_parentheses?(node) ||
              assignment_in_condition?(node) ||
              forwards_anonymous_rest_arguments?(node)
          end

          def call_in_literals?(node)
            parent = node.parent&.any_block_type? ? node.parent.parent : node.parent
            return false unless parent

            parent.type?(:pair, :array, :range) ||
              splat?(parent) ||
              ternary_if?(parent)
          end

          def call_in_logical_operators?(node)
            parent = node.parent&.any_block_type? ? node.parent.parent : node.parent
            return false unless parent

            logical_operator?(parent) ||
              (parent.send_type? &&
              parent.arguments.any? { |argument| logical_operator?(argument) })
          end

          def call_in_optional_arguments?(node)
            node.parent&.type?(:optarg, :kwoptarg)
          end

          def call_in_single_line_inheritance?(node)
            node.parent&.class_type? && node.parent.single_line?
          end

          # rubocop:disable Metrics/PerceivedComplexity
          def call_with_ambiguous_arguments?(node)
            call_with_braced_block?(node) ||
              call_in_argument_with_block?(node) ||
              call_as_argument_or_chain?(node) ||
              call_in_match_pattern?(node) ||
              hash_literal_in_arguments?(node) ||
              ambiguous_range_argument?(node) ||
              node.descendants.any? do |n|
                n.type?(:forwarded_args, :any_block) ||
                  ambiguous_literal?(n) || logical_operator?(n)
              end
          end
          # rubocop:enable Metrics/PerceivedComplexity

          def call_with_braced_block?(node)
            node.type?(:call, :super) && node.block_node&.braces?
          end

          def call_in_argument_with_block?(node)
            parent = node.parent&.any_block_type? && node.parent.parent
            return false unless parent

            parent.type?(:call, :super, :yield)
          end

          def call_as_argument_or_chain?(node)
            node.parent&.type?(:call, :super, :yield) &&
              !assigned_before?(node.parent, node)
          end

          def call_in_match_pattern?(node)
            return false unless (parent = node.parent)

            parent.type?(:match_pattern, :match_pattern_p)
          end

          def hash_literal_in_arguments?(node)
            node.arguments.any? do |n|
              hash_literal?(n) ||
                (n.send_type? && node.descendants.any? { |descendant| hash_literal?(descendant) })
            end
          end

          def ambiguous_range_argument?(node)
            return true if (first_arg = node.first_argument)&.range_type? && first_arg.begin.nil?
            return true if (last_arg = node.last_argument)&.range_type? && last_arg.end.nil?

            false
          end

          def allowed_multiline_call_with_parentheses?(node)
            cop_config['AllowParenthesesInMultilineCall'] && node.multiline?
          end

          def allowed_chained_call_with_parentheses?(node)
            return false unless cop_config['AllowParenthesesInChaining']

            previous = node.descendants.first
            return false unless previous&.send_type?

            previous.parenthesized? || allowed_chained_call_with_parentheses?(previous)
          end

          def ambiguous_literal?(node)
            splat?(node) || ternary_if?(node) || regexp_slash_literal?(node) || unary_literal?(node)
          end

          def splat?(node)
            node.type?(:splat, :kwsplat, :block_pass)
          end

          def ternary_if?(node)
            node.if_type? && node.ternary?
          end

          def logical_operator?(node)
            node.operator_keyword? && node.logical_operator?
          end

          def hash_literal?(node)
            node.hash_type? && node.braces?
          end

          def regexp_slash_literal?(node)
            node.regexp_type? && node.loc.begin.source == '/'
          end

          def unary_literal?(node)
            # NOTE: should be removed after releasing https://github.com/rubocop/rubocop-ast/pull/379
            return node.source.match?(/\A[+-]/) if node.complex_type?

            (node.numeric_type? && node.sign?) ||
              (node.parent&.send_type? && node.parent.unary_operation?)
          end

          def assigned_before?(node, target)
            node.assignment? && node.loc.operator.begin < target.loc.begin
          end

          def inside_string_interpolation?(node)
            node.ancestors.drop_while { |a| !a.begin_type? }.any?(&:dstr_type?)
          end

          def assignment_in_condition?(node)
            parent = node.parent
            return false unless parent

            grandparent = parent.parent
            return false unless grandparent

            parent.assignment? && (grandparent.conditional? || grandparent.when_type?)
          end

          def forwards_anonymous_rest_arguments?(node)
            return false unless (last_argument = node.last_argument)
            return true if last_argument.forwarded_restarg_type?

            last_argument.hash_type? && last_argument.children.first&.forwarded_kwrestarg_type?
          end
        end
        # rubocop:enable Metrics/ModuleLength, Metrics/CyclomaticComplexity
      end
    end
  end
end
