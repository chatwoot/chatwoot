# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that operators have space around them, except for ** which
      # should or shouldn't have surrounding space depending on configuration.
      # It allows vertical alignment consisting of one or more whitespace
      # around operators.
      #
      # This cop has `AllowForAlignment` option. When `true`, allows most
      # uses of extra spacing if the intent is to align with an operator on
      # the previous or next line, not counting empty lines or comment lines.
      #
      # @example
      #   # bad
      #   total = 3*4
      #   "apple"+"juice"
      #   my_number = 38/4
      #
      #   # good
      #   total = 3 * 4
      #   "apple" + "juice"
      #   my_number = 38 / 4
      #
      # @example AllowForAlignment: true (default)
      #   # good
      #   {
      #     1 =>  2,
      #     11 => 3
      #   }
      #
      # @example AllowForAlignment: false
      #   # bad
      #   {
      #     1 =>  2,
      #     11 => 3
      #   }
      #
      # @example EnforcedStyleForExponentOperator: no_space (default)
      #   # bad
      #   a ** b
      #
      #   # good
      #   a**b
      #
      # @example EnforcedStyleForExponentOperator: space
      #   # bad
      #   a**b
      #
      #   # good
      #   a ** b
      #
      # @example EnforcedStyleForRationalLiterals: no_space (default)
      #   # bad
      #   1 / 48r
      #
      #   # good
      #   1/48r
      #
      # @example EnforcedStyleForRationalLiterals: space
      #   # bad
      #   1/48r
      #
      #   # good
      #   1 / 48r
      class SpaceAroundOperators < Base
        include PrecedingFollowingAlignment
        include RangeHelp
        include RationalLiteral
        extend AutoCorrector

        IRREGULAR_METHODS = %i[[] ! []=].freeze
        EXCESSIVE_SPACE = '  '

        def self.autocorrect_incompatible_with
          [Style::SelfAssignment]
        end

        def on_sclass(node)
          check_operator(:sclass, node.loc.operator, node)
        end

        def on_pair(node)
          return unless node.hash_rocket?

          return if hash_table_style? && !node.parent.pairs_on_same_line?

          check_operator(:pair, node.loc.operator, node)
        end

        def on_if(node)
          return unless node.ternary?

          check_operator(:if, node.loc.question, node.if_branch)
          check_operator(:if, node.loc.colon, node.else_branch)
        end

        def on_resbody(node)
          return unless node.loc.assoc

          check_operator(:resbody, node.loc.assoc, node.exception_variable)
        end

        def on_send(node)
          return if rational_literal?(node)

          if node.setter_method?
            on_setter_method(node)
          elsif regular_operator?(node)
            check_operator(:send, node.loc.selector, node.first_argument)
          end
        end

        def on_assignment(node)
          rhs = node.rhs

          return unless rhs

          type = node.op_asgn_type? ? :special_asgn : :assignment
          check_operator(type, node.loc.operator, rhs)
        end

        def on_class(node)
          rhs = node.parent_class

          return unless rhs

          check_operator(:class, node.loc.operator, rhs)
        end

        def on_binary(node)
          rhs = node.rhs

          return unless rhs

          check_operator(:binary, node.loc.operator, rhs)
        end

        def on_setter_method(node)
          rhs = node.first_argument

          return unless rhs

          check_operator(:special_asgn, node.loc.operator, node.first_argument)
        end

        def on_match_pattern(node)
          return if target_ruby_version < 3.0

          check_operator(:match_pattern, node.loc.operator, node)
        end

        alias on_or       on_binary
        alias on_and      on_binary
        alias on_lvasgn   on_assignment
        alias on_casgn    on_assignment
        alias on_masgn    on_assignment
        alias on_ivasgn   on_assignment
        alias on_cvasgn   on_assignment
        alias on_gvasgn   on_assignment
        alias on_or_asgn  on_assignment
        alias on_and_asgn on_assignment
        alias on_op_asgn  on_assignment

        private

        def regular_operator?(send_node)
          return false if send_node.unary_operation? || send_node.dot? || send_node.double_colon?

          operator_with_regular_syntax?(send_node)
        end

        def operator_with_regular_syntax?(send_node)
          send_node.operator_method? && !IRREGULAR_METHODS.include?(send_node.method_name)
        end

        def check_operator(type, operator, right_operand)
          with_space = range_with_surrounding_space(operator)
          return if with_space.source.start_with?("\n")

          comment = processed_source.comment_at_line(operator.line)
          return if comment && with_space.last_column == comment.loc.column

          offense(type, operator, with_space, right_operand) do |msg|
            add_offense(operator, message: msg) do |corrector|
              autocorrect(corrector, with_space, right_operand)
            end
          end
        end

        def offense(type, operator, with_space, right_operand)
          msg = offense_message(type, operator, with_space, right_operand)
          yield msg if msg
        end

        def autocorrect(corrector, range, right_operand)
          range_source = range.source

          if range_source.include?('**') && !space_around_exponent_operator?
            corrector.replace(range, '**')
          elsif range_source.include?('/') && !space_around_slash_operator?(right_operand)
            corrector.replace(range, '/')
          elsif range_source.end_with?("\n")
            corrector.replace(range, " #{range_source.strip}\n")
          else
            enclose_operator_with_space(corrector, range)
          end
        end

        def enclose_operator_with_space(corrector, range)
          operator = range.source

          # If `ForceEqualSignAlignment` is true, `Layout/ExtraSpacing` cop
          # inserts spaces before operator. If `Layout/SpaceAroundOperators` cop
          # inserts a space, it collides and raises the infinite loop error.
          if force_equal_sign_alignment? && !operator.end_with?(' ')
            corrector.insert_after(range, ' ')
          else
            corrector.replace(range, " #{operator.strip} ")
          end
        end

        def offense_message(type, operator, with_space, right_operand)
          if should_not_have_surrounding_space?(operator, right_operand)
            return if with_space.is?(operator.source)

            "Space around operator `#{operator.source}` detected."
          elsif !/^\s.*\s$/.match?(with_space.source)
            "Surrounding space missing for operator `#{operator.source}`."
          elsif excess_leading_space?(type, operator, with_space) ||
                excess_trailing_space?(right_operand.source_range, with_space)
            "Operator `#{operator.source}` should be surrounded " \
              'by a single space.'
          end
        end

        def excess_leading_space?(type, operator, with_space)
          return false unless allow_for_alignment?
          return false unless with_space.source.start_with?(EXCESSIVE_SPACE)

          return !aligned_with_operator?(operator) unless type == :assignment

          token            = Token.new(operator, nil, operator.source)
          align_preceding  = aligned_with_preceding_equals_operator(token)

          return false if align_preceding == :yes ||
                          aligned_with_subsequent_equals_operator(token) == :none

          aligned_with_subsequent_equals_operator(token) != :yes
        end

        def excess_trailing_space?(right_operand, with_space)
          with_space.source.end_with?(EXCESSIVE_SPACE) &&
            (!allow_for_alignment? || !aligned_with_something?(right_operand))
        end

        def align_hash_cop_config
          config.for_cop('Layout/HashAlignment')
        end

        def hash_table_style?
          return false unless align_hash_cop_config

          enforced_styles = Array(align_hash_cop_config['EnforcedHashRocketStyle'])
          enforced_styles.include?('table')
        end

        def space_around_exponent_operator?
          cop_config['EnforcedStyleForExponentOperator'] == 'space'
        end

        def space_around_slash_operator?(right_operand)
          return true unless right_operand.rational_type?

          cop_config['EnforcedStyleForRationalLiterals'] == 'space'
        end

        def force_equal_sign_alignment?
          config.for_cop('Layout/ExtraSpacing')['ForceEqualSignAlignment']
        end

        def should_not_have_surrounding_space?(operator, right_operand)
          if operator.is?('**')
            !space_around_exponent_operator?
          elsif operator.is?('/')
            !space_around_slash_operator?(right_operand)
          else
            false
          end
        end
      end
    end
  end
end
