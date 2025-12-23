# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant assignment before returning.
      #
      # @example
      #   # bad
      #   def test
      #     x = foo
      #     x
      #   end
      #
      #   # bad
      #   def test
      #     if x
      #       z = foo
      #       z
      #     elsif y
      #       z = bar
      #       z
      #     end
      #   end
      #
      #   # good
      #   def test
      #     foo
      #   end
      #
      #   # good
      #   def test
      #     if x
      #       foo
      #     elsif y
      #       bar
      #     end
      #   end
      #
      class RedundantAssignment < Base
        extend AutoCorrector

        MSG = 'Redundant assignment before returning detected.'

        # @!method redundant_assignment?(node)
        def_node_matcher :redundant_assignment?, <<~PATTERN
          (... $(lvasgn _name _expression) (lvar _name))
        PATTERN

        def on_def(node)
          check_branch(node.body)
        end
        alias on_defs on_def

        private

        # rubocop:disable Metrics/CyclomaticComplexity
        def check_branch(node)
          return unless node

          case node.type
          when :case       then check_case_node(node)
          when :case_match then check_case_match_node(node)
          when :if         then check_if_node(node)
          when :rescue, :resbody
            check_rescue_node(node)
          when :ensure then check_ensure_node(node)
          when :begin, :kwbegin
            check_begin_node(node)
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def check_case_node(node)
          node.when_branches.each { |when_node| check_branch(when_node.body) }
          check_branch(node.else_branch)
        end

        def check_case_match_node(node)
          node.in_pattern_branches.each { |in_pattern_node| check_branch(in_pattern_node.body) }
          check_branch(node.else_branch)
        end

        def check_if_node(node)
          return if node.modifier_form? || node.ternary?

          check_branch(node.if_branch)
          check_branch(node.else_branch)
        end

        def check_rescue_node(node)
          node.child_nodes.each { |child_node| check_branch(child_node) }
        end

        def check_ensure_node(node)
          check_branch(node.branch)
        end

        def check_begin_node(node)
          if (assignment = redundant_assignment?(node))
            add_offense(assignment) do |corrector|
              expression = assignment.children[1]
              corrector.replace(assignment, expression.source)
              corrector.remove(assignment.right_sibling)
            end
          else
            last_expr = node.children.last
            check_branch(last_expr)
          end
        end
      end
    end
  end
end
