# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for unwanted parentheses in parameterless method calls.
      #
      # This cop's allowed methods can be customized with `AllowedMethods`.
      # By default, there are no allowed methods.
      #
      # NOTE: This cop allows the use of `it()` without arguments in blocks,
      # as in `0.times { it() }`, following `Lint/ItWithoutArgumentsInBlock` cop.
      #
      # @example
      #   # bad
      #   object.some_method()
      #
      #   # good
      #   object.some_method
      #
      # @example AllowedMethods: [] (default)
      #   # bad
      #   object.foo()
      #
      # @example AllowedMethods: [foo]
      #   # good
      #   object.foo()
      #
      class MethodCallWithoutArgsParentheses < Base
        include AllowedMethods
        include AllowedPattern
        extend AutoCorrector

        MSG = 'Do not use parentheses for method calls with no arguments.'

        # rubocop:disable Metrics/CyclomaticComplexity
        def on_send(node)
          return unless !node.arguments? && node.parenthesized?
          return if ineligible_node?(node)
          return if default_argument?(node)
          return if allowed_method_name?(node.method_name)
          return if same_name_assignment?(node)
          return if parenthesized_it_method_in_block?(node)

          register_offense(node)
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        alias on_csend on_send

        private

        def register_offense(node)
          add_offense(offense_range(node)) do |corrector|
            corrector.remove(node.loc.begin)
            corrector.remove(node.loc.end)
          end
        end

        def ineligible_node?(node)
          node.camel_case_method? || node.implicit_call? || node.prefix_not?
        end

        def default_argument?(node)
          node.parent&.optarg_type?
        end

        def allowed_method_name?(name)
          allowed_method?(name) || matches_allowed_pattern?(name)
        end

        def same_name_assignment?(node)
          return false if node.receiver

          any_assignment?(node) do |asgn_node|
            if asgn_node.masgn_type?
              variable_in_mass_assignment?(node.method_name, asgn_node)
            else
              asgn_node.loc.name.source == node.method_name.to_s
            end
          end
        end

        # Respects `Lint/ItWithoutArgumentsInBlock` cop and the following Ruby 3.3's warning:
        #
        # $ ruby -e '0.times { begin; it; end }'
        # -e:1: warning: `it` calls without arguments will refer to the first block param in
        # Ruby 3.4; use it() or self.it
        #
        def parenthesized_it_method_in_block?(node)
          return false unless node.method?(:it)
          return false unless (block_node = node.each_ancestor(:block).first)
          return false unless block_node.arguments.empty_and_without_delimiters?

          !node.receiver && node.arguments.empty? && !node.block_literal?
        end

        def any_assignment?(node)
          node.each_ancestor(*AST::Node::ASSIGNMENTS).any? do |asgn_node|
            # `obj.method = value` parses as (send ... :method= ...), and will
            # not be returned as an `asgn_node` here, however,
            # `obj.method ||= value` parses as (or-asgn (send ...) ...)
            # which IS an `asgn_node`. Similarly, `obj.method += value` parses
            # as (op-asgn (send ...) ...), which is also an `asgn_node`.
            next if asgn_node.shorthand_asgn? && asgn_node.lhs.call_type?

            yield asgn_node
          end
        end

        def variable_in_mass_assignment?(variable_name, node)
          node.assignments.reject(&:send_type?).any? { |n| n.name == variable_name }
        end

        def offense_range(node)
          node.loc.begin.join(node.loc.end)
        end
      end
    end
  end
end
