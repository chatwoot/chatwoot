# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant parentheses.
      #
      # @example
      #
      #   # bad
      #   (x) if ((y.z).nil?)
      #
      #   # good
      #   x if y.z.nil?
      #
      class RedundantParentheses < Base # rubocop:disable Metrics/ClassLength
        include Parentheses
        extend AutoCorrector

        ALLOWED_NODE_TYPES = %i[or send splat kwsplat].freeze

        # @!method square_brackets?(node)
        def_node_matcher :square_brackets?, <<~PATTERN
          (send `{(send _recv _msg) str array hash const #variable?} :[] ...)
        PATTERN

        # @!method method_node_and_args(node)
        def_node_matcher :method_node_and_args, '$(call _recv _msg $...)'

        # @!method rescue?(node)
        def_node_matcher :rescue?, '{^resbody ^^resbody}'

        # @!method allowed_pin_operator?(node)
        def_node_matcher :allowed_pin_operator?, '^(pin (begin !{lvar ivar cvar gvar}))'

        def on_begin(node)
          return if !parentheses?(node) || parens_allowed?(node) || ignore_syntax?(node)

          check(node)
        end

        private

        def variable?(node)
          node.respond_to?(:variable?) && node.variable?
        end

        def parens_allowed?(node)
          empty_parentheses?(node) ||
            first_arg_begins_with_hash_literal?(node) ||
            rescue?(node) ||
            allowed_pin_operator?(node) ||
            allowed_expression?(node)
        end

        def ignore_syntax?(node)
          return false unless (parent = node.parent)

          parent.type?(:while_post, :until_post, :match_with_lvasgn) ||
            like_method_argument_parentheses?(parent) || multiline_control_flow_statements?(node)
        end

        def allowed_expression?(node)
          allowed_ancestor?(node) ||
            allowed_multiple_expression?(node) ||
            allowed_ternary?(node) ||
            node.parent&.range_type?
        end

        def allowed_ancestor?(node)
          # Don't flag `break(1)`, etc
          keyword_ancestor?(node) && parens_required?(node)
        end

        def allowed_multiple_expression?(node)
          return false if node.children.one?

          ancestor = node.ancestors.first
          return false unless ancestor

          !ancestor.type?(:begin, :any_def, :any_block)
        end

        def allowed_ternary?(node)
          return false unless node&.parent&.if_type?

          node.parent.ternary? && ternary_parentheses_required?
        end

        def ternary_parentheses_required?
          config = @config.for_cop('Style/TernaryParentheses')
          allowed_styles = %w[require_parentheses require_parentheses_when_complex]

          config.fetch('Enabled') && allowed_styles.include?(config['EnforcedStyle'])
        end

        def like_method_argument_parentheses?(node)
          return false unless node.type?(:send, :super, :yield)

          node.arguments.one? && !node.parenthesized? &&
            !node.operator_method? && node.first_argument.begin_type?
        end

        def multiline_control_flow_statements?(node)
          return false unless (parent = node.parent)
          return false if parent.single_line?

          parent.type?(:return, :next, :break)
        end

        def empty_parentheses?(node)
          # Don't flag `()`
          node.children.empty?
        end

        def first_arg_begins_with_hash_literal?(node)
          # Don't flag `method ({key: value})` or `method ({key: value}.method)`
          hash_literal = method_chain_begins_with_hash_literal(node.children.first)
          if (root_method = node.each_ancestor(:send).to_a.last)
            parenthesized = root_method.parenthesized_call?
          end
          hash_literal && first_argument?(node) && !parentheses?(hash_literal) && !parenthesized
        end

        def method_chain_begins_with_hash_literal(node)
          return if node.nil?
          return node if node.hash_type?
          return unless node.send_type?

          method_chain_begins_with_hash_literal(node.children.first)
        end

        def check(begin_node)
          node = begin_node.children.first

          if (message = find_offense_message(begin_node, node))
            if node.range_type? && !argument_of_parenthesized_method_call?(begin_node)
              begin_node = begin_node.parent
            end

            return offense(begin_node, message)
          end

          check_send(begin_node, node) if node.call_type?
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        def find_offense_message(begin_node, node)
          return 'a keyword' if keyword_with_redundant_parentheses?(node)
          return 'a literal' if node.literal? && disallowed_literal?(begin_node, node)
          return 'a variable' if node.variable?
          return 'a constant' if node.const_type?
          if node.assignment? && (begin_node.parent.nil? || begin_node.parent.begin_type?)
            return 'an assignment'
          end
          if node.lambda_or_proc? && (node.braces? || node.send_node.lambda_literal?)
            return 'an expression'
          end
          return 'an interpolated expression' if interpolation?(begin_node)
          return 'a method argument' if argument_of_parenthesized_method_call?(begin_node)

          return if begin_node.chained?

          if node.operator_keyword?
            return if node.semantic_operator? && begin_node.parent
            return if node.multiline? && allow_in_multiline_conditions?
            return if ALLOWED_NODE_TYPES.include?(begin_node.parent&.type)
            return if !node.and_type? && begin_node.parent&.and_type?
            return if begin_node.parent&.if_type? && begin_node.parent.ternary?

            'a logical expression'
          elsif node.respond_to?(:comparison_method?) && node.comparison_method?
            return unless begin_node.parent.nil?

            'a comparison expression'
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

        # @!method interpolation?(node)
        def_node_matcher :interpolation?, '[^begin ^^dstr]'

        def argument_of_parenthesized_method_call?(begin_node)
          node = begin_node.children.first
          return false if node.basic_conditional? || method_call_parentheses_required?(node)
          return false unless (parent = begin_node.parent)

          parent.call_type? && parent.parenthesized? && parent.receiver != begin_node
        end

        def method_call_parentheses_required?(node)
          return false unless node.call_type?

          (node.receiver.nil? || node.loc.dot) && node.arguments.any?
        end

        def allow_in_multiline_conditions?
          !!config.for_enabled_cop('Style/ParenthesesAroundCondition')['AllowInMultilineConditions']
        end

        def check_send(begin_node, node)
          return check_unary(begin_node, node) if node.unary_operation?

          return unless method_call_with_redundant_parentheses?(node)
          return if call_chain_starts_with_int?(begin_node, node) ||
                    do_end_block_in_method_chain?(begin_node, node)

          offense(begin_node, 'a method call')
        end

        def check_unary(begin_node, node)
          return if begin_node.chained?

          node = node.children.first while suspect_unary?(node)

          return if node.send_type? && !method_call_with_redundant_parentheses?(node)

          offense(begin_node, 'a unary operation')
        end

        def offense(node, msg)
          add_offense(node, message: "Don't use parentheses around #{msg}.") do |corrector|
            ParenthesesCorrector.correct(corrector, node)
          end
        end

        def suspect_unary?(node)
          node.send_type? && node.unary_operation? && !node.prefix_not?
        end

        def keyword_ancestor?(node)
          node.parent&.keyword?
        end

        def disallowed_literal?(begin_node, node)
          if node.range_type?
            return false unless (parent = begin_node.parent)

            parent.begin_type? && parent.children.one?
          else
            !raised_to_power_negative_numeric?(begin_node, node)
          end
        end

        def raised_to_power_negative_numeric?(begin_node, node)
          return false unless node.numeric_type?

          next_sibling = begin_node.right_sibling
          return false unless next_sibling

          base_value = node.children.first

          base_value.negative? && next_sibling == :**
        end

        def keyword_with_redundant_parentheses?(node)
          return false unless node.keyword?
          return true if node.special_keyword?

          args = *node

          if only_begin_arg?(args)
            parentheses?(args.first)
          else
            args.empty? || parentheses?(node)
          end
        end

        def method_call_with_redundant_parentheses?(node)
          return false unless node.call_type?
          return false if node.prefix_not?

          send_node, args = method_node_and_args(node)

          args.empty? || parentheses?(send_node) || square_brackets?(send_node)
        end

        def only_begin_arg?(args)
          args.one? && args.first&.begin_type?
        end

        def first_argument?(node)
          if first_send_argument?(node) ||
             first_super_argument?(node) ||
             first_yield_argument?(node)
            return true
          end

          node.each_ancestor.any? { |ancestor| first_argument?(ancestor) }
        end

        # @!method first_send_argument?(node)
        def_node_matcher :first_send_argument?, <<~PATTERN
          ^(send _ _ equal?(%0) ...)
        PATTERN

        # @!method first_super_argument?(node)
        def_node_matcher :first_super_argument?, <<~PATTERN
          ^(super equal?(%0) ...)
        PATTERN

        # @!method first_yield_argument?(node)
        def_node_matcher :first_yield_argument?, <<~PATTERN
          ^(yield equal?(%0) ...)
        PATTERN

        def call_chain_starts_with_int?(begin_node, send_node)
          recv = first_part_of_call_chain(send_node)
          recv&.int_type? && (parent = begin_node.parent) &&
            parent.send_type? && (parent.method?(:-@) || parent.method?(:+@))
        end

        def do_end_block_in_method_chain?(begin_node, node)
          return false unless (block = node.each_descendant(:any_block).first)

          block.keywords? && begin_node.each_ancestor(:call).any?
        end
      end
    end
  end
end
