# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for unreachable code.
      # The check are based on the presence of flow of control
      # statement in non-final position in `begin` (implicit) blocks.
      #
      # @example
      #
      #   # bad
      #   def some_method
      #     return
      #     do_something
      #   end
      #
      #   # bad
      #   def some_method
      #     if cond
      #       return
      #     else
      #       return
      #     end
      #     do_something
      #   end
      #
      #   # good
      #   def some_method
      #     do_something
      #   end
      class UnreachableCode < Base
        MSG = 'Unreachable code detected.'

        def initialize(config = nil, options = nil)
          super
          @redefined = []
          @instance_eval_count = 0
        end

        def on_block(node)
          @instance_eval_count += 1 if instance_eval_block?(node)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        def after_block(node)
          @instance_eval_count -= 1 if instance_eval_block?(node)
        end

        def on_begin(node)
          expressions = *node

          expressions.each_cons(2) do |expression1, expression2|
            next unless flow_expression?(expression1)

            add_offense(expression2)
          end
        end

        alias on_kwbegin on_begin

        private

        def redefinable_flow_method?(method)
          %i[raise fail throw exit exit! abort].include? method
        end

        # @!method flow_command?(node)
        def_node_matcher :flow_command?, <<~PATTERN
          {
            return next break retry redo
            (send
             {nil? (const {nil? cbase} :Kernel)}
             #redefinable_flow_method?
             ...)
          }
        PATTERN

        def flow_expression?(node)
          return report_on_flow_command?(node) if flow_command?(node)

          case node.type
          when :begin, :kwbegin
            expressions = *node
            expressions.any? { |expr| flow_expression?(expr) }
          when :if
            check_if(node)
          when :case, :case_match
            check_case(node)
          when :def
            register_redefinition(node)
          else
            false
          end
        end

        def check_if(node)
          if_branch = node.if_branch
          else_branch = node.else_branch
          if_branch && else_branch && flow_expression?(if_branch) && flow_expression?(else_branch)
        end

        def check_case(node)
          else_branch = node.else_branch
          return false unless else_branch
          return false unless flow_expression?(else_branch)

          branches = node.case_type? ? node.when_branches : node.in_pattern_branches

          branches.all? { |branch| branch.body && flow_expression?(branch.body) }
        end

        def register_redefinition(node)
          @redefined << node.method_name if redefinable_flow_method? node.method_name
          false
        end

        def instance_eval_block?(node)
          node.any_block_type? && node.method?(:instance_eval)
        end

        def report_on_flow_command?(node)
          return true unless node.send_type?

          # By the contract of this function, this case means that
          # the method is called on `Kernel` in which case we
          # always want to report a warning.
          return true if node.receiver

          # Inside an `instance_eval` we have no way to tell the
          # type of `self` just by looking at the AST, so we can't
          # tell if the give function that's called has been
          # redefined or not, so to avoid false positives, we silence
          # the warning.
          return false if @instance_eval_count.positive?

          !@redefined.include? node.method_name
        end
      end
    end
  end
end
