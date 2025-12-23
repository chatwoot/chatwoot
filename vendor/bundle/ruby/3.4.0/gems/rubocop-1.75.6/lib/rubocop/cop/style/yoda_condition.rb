# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces or forbids Yoda conditions,
      # i.e. comparison operations where the order of expression is reversed.
      # eg. `5 == x`
      #
      # @safety
      #   This cop is unsafe because comparison operators can be defined
      #   differently on different classes, and are not guaranteed to
      #   have the same result if reversed.
      #
      #   For example:
      #
      #   [source,ruby]
      #   ----
      #   class MyKlass
      #     def ==(other)
      #       true
      #     end
      #   end
      #
      #   obj = MyKlass.new
      #   obj == 'string'   #=> true
      #   'string' == obj   #=> false
      #   ----
      #
      # @example EnforcedStyle: forbid_for_all_comparison_operators (default)
      #   # bad
      #   99 == foo
      #   "bar" != foo
      #   42 >= foo
      #   10 < bar
      #   99 == CONST
      #
      #   # good
      #   foo == 99
      #   foo == "bar"
      #   foo <= 42
      #   bar > 10
      #   CONST == 99
      #   "#{interpolation}" == foo
      #   /#{interpolation}/ == foo
      #
      # @example EnforcedStyle: forbid_for_equality_operators_only
      #   # bad
      #   99 == foo
      #   "bar" != foo
      #
      #   # good
      #   99 >= foo
      #   3 < a && a < 5
      #
      # @example EnforcedStyle: require_for_all_comparison_operators
      #   # bad
      #   foo == 99
      #   foo == "bar"
      #   foo <= 42
      #   bar > 10
      #
      #   # good
      #   99 == foo
      #   "bar" != foo
      #   42 >= foo
      #   10 < bar
      #
      # @example EnforcedStyle: require_for_equality_operators_only
      #   # bad
      #   99 >= foo
      #   3 < a && a < 5
      #
      #   # good
      #   99 == foo
      #   "bar" != foo
      class YodaCondition < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG = 'Reverse the order of the operands `%<source>s`.'
        REVERSE_COMPARISON = { '<' => '>', '<=' => '>=', '>' => '<', '>=' => '<=' }.freeze
        EQUALITY_OPERATORS = %i[== !=].freeze
        NONCOMMUTATIVE_OPERATORS = %i[===].freeze
        PROGRAM_NAMES = %i[$0 $PROGRAM_NAME].freeze
        RESTRICT_ON_SEND = RuboCop::AST::Node::COMPARISON_OPERATORS
        ENFORCE_YODA_STYLES = %i[
          require_for_all_comparison_operators require_for_equality_operators_only
        ].freeze
        EQUALITY_ONLY_STYLES = %i[
          forbid_for_equality_operators_only require_for_equality_operators_only
        ].freeze

        # @!method file_constant_equal_program_name?(node)
        def_node_matcher :file_constant_equal_program_name?, <<~PATTERN
          (send #source_file_path_constant? {:== :!=} (gvar #program_name?))
        PATTERN

        def on_send(node)
          return unless yoda_compatible_condition?(node)
          return if (equality_only? && non_equality_operator?(node)) ||
                    file_constant_equal_program_name?(node) ||
                    valid_yoda?(node)

          add_offense(node) do |corrector|
            corrector.replace(actual_code_range(node), corrected_code(node))
          end
        end

        private

        def enforce_yoda?
          ENFORCE_YODA_STYLES.include?(style)
        end

        def equality_only?
          EQUALITY_ONLY_STYLES.include?(style)
        end

        def yoda_compatible_condition?(node)
          node.comparison_method? && !noncommutative_operator?(node)
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def valid_yoda?(node)
          return true unless (rhs = node.first_argument)

          lhs = node.receiver
          return true if (constant_portion?(lhs) && constant_portion?(rhs)) ||
                         (!constant_portion?(lhs) && !constant_portion?(rhs)) ||
                         interpolation?(lhs)

          enforce_yoda? ? constant_portion?(lhs) : constant_portion?(rhs)
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def message(node)
          format(MSG, source: node.source)
        end

        def corrected_code(node)
          lhs = node.receiver
          rhs = node.first_argument

          "#{rhs.source} #{reverse_comparison(node.method_name)} #{lhs.source}"
        end

        def constant_portion?(node)
          node.literal? || node.const_type?
        end

        def actual_code_range(node)
          range_between(node.source_range.begin_pos, node.source_range.end_pos)
        end

        def reverse_comparison(operator)
          REVERSE_COMPARISON.fetch(operator.to_s, operator)
        end

        def non_equality_operator?(node)
          !EQUALITY_OPERATORS.include?(node.method_name)
        end

        def noncommutative_operator?(node)
          NONCOMMUTATIVE_OPERATORS.include?(node.method_name)
        end

        def source_file_path_constant?(node)
          node.source == '__FILE__'
        end

        def program_name?(name)
          PROGRAM_NAMES.include?(name)
        end

        def interpolation?(node)
          return true if node.dstr_type?

          node.regexp_type? && node.interpolation?
        end
      end
    end
  end
end
