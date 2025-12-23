# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for potential usage of the `||=` operator.
      #
      # @example
      #   # bad
      #   name = name ? name : 'Bozhidar'
      #
      #   # bad
      #   name = if name
      #            name
      #          else
      #            'Bozhidar'
      #          end
      #
      #   # bad
      #   unless name
      #     name = 'Bozhidar'
      #   end
      #
      #   # bad
      #   name = 'Bozhidar' unless name
      #
      #   # good - set name to 'Bozhidar', only if it's nil or false
      #   name ||= 'Bozhidar'
      class OrAssignment < Base
        extend AutoCorrector

        MSG = 'Use the double pipe equals operator `||=` instead.'

        # @!method ternary_assignment?(node)
        def_node_matcher :ternary_assignment?, <<~PATTERN
          ({lvasgn ivasgn cvasgn gvasgn} _var
            (if
              ({lvar ivar cvar gvar} _var)
              ({lvar ivar cvar gvar} _var)
              $_))
        PATTERN

        # @!method unless_assignment?(node)
        def_node_matcher :unless_assignment?, <<~PATTERN
          (if
            ({lvar ivar cvar gvar} _var) nil?
            ({lvasgn ivasgn cvasgn gvasgn} _var
              _))
        PATTERN

        def on_if(node)
          return unless unless_assignment?(node)

          add_offense(node) { |corrector| autocorrect(corrector, node) }
        end

        def on_lvasgn(node)
          return unless (else_branch = ternary_assignment?(node))
          return if else_branch.if_type?

          add_offense(node) { |corrector| autocorrect(corrector, node) }
        end

        alias on_ivasgn on_lvasgn
        alias on_cvasgn on_lvasgn
        alias on_gvasgn on_lvasgn

        private

        def autocorrect(corrector, node)
          if ternary_assignment?(node)
            variable, default = take_variable_and_default_from_ternary(node)
          else
            variable, default = take_variable_and_default_from_unless(node)
          end

          corrector.replace(node, "#{variable} ||= #{default.source}")
        end

        def take_variable_and_default_from_ternary(node)
          [node.name, node.expression.else_branch]
        end

        def take_variable_and_default_from_unless(node)
          if node.if_branch
            [node.if_branch.name, node.if_branch.expression]
          else
            [node.else_branch.name, node.else_branch.expression]
          end
        end
      end
    end
  end
end
