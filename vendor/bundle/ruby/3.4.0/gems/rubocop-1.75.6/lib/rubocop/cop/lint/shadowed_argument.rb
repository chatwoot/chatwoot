# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for shadowed arguments.
      #
      # This cop has `IgnoreImplicitReferences` configuration option.
      # It means argument shadowing is used in order to pass parameters
      # to zero arity `super` when `IgnoreImplicitReferences` is `true`.
      #
      # @example
      #
      #   # bad
      #   do_something do |foo|
      #     foo = 42
      #     puts foo
      #   end
      #
      #   def do_something(foo)
      #     foo = 42
      #     puts foo
      #   end
      #
      #   # good
      #   do_something do |foo|
      #     foo = foo + 42
      #     puts foo
      #   end
      #
      #   def do_something(foo)
      #     foo = foo + 42
      #     puts foo
      #   end
      #
      #   def do_something(foo)
      #     puts foo
      #   end
      #
      # @example IgnoreImplicitReferences: false (default)
      #
      #   # bad
      #   def do_something(foo)
      #     foo = 42
      #     super
      #   end
      #
      #   def do_something(foo)
      #     foo = super
      #     bar
      #   end
      #
      # @example IgnoreImplicitReferences: true
      #
      #   # good
      #   def do_something(foo)
      #     foo = 42
      #     super
      #   end
      #
      #   def do_something(foo)
      #     foo = super
      #     bar
      #   end
      #
      class ShadowedArgument < Base
        MSG = 'Argument `%<argument>s` was shadowed by a local variable before it was used.'

        # @!method uses_var?(node)
        def_node_search :uses_var?, '(lvar %)'

        def self.joining_forces
          VariableForce
        end

        def after_leaving_scope(scope, _variable_table)
          scope.variables.each_value { |variable| check_argument(variable) }
        end

        private

        def check_argument(argument)
          return unless argument.method_argument? || argument.block_argument?
          # Block local variables, i.e., variables declared after ; inside
          # |...| aren't really arguments.
          return if argument.explicit_block_local_variable?

          shadowing_assignment(argument) do |node|
            message = format(MSG, argument: argument.name)

            add_offense(node, message: message)
          end
        end

        def shadowing_assignment(argument)
          return unless argument.referenced?

          assignment_without_argument_usage(argument) do |node, location_known|
            assignment_without_usage_pos = node.source_range.begin_pos

            references = argument_references(argument)

            # If argument was referenced before it was reassigned
            # then it's not shadowed
            next if references.any? do |reference|
              next true if !reference.explicit? && ignore_implicit_references?

              reference_pos(reference.node) <= assignment_without_usage_pos
            end

            yield location_known ? node : argument.declaration_node
          end
        end

        # Find the first argument assignment, which doesn't reference the
        # argument at the rhs. If the assignment occurs inside a branch or
        # block, it is impossible to tell whether it's executed, so precise
        # shadowing location is not known.
        #
        def assignment_without_argument_usage(argument)
          argument.assignments.reduce(true) do |location_known, assignment|
            assignment_node = assignment.meta_assignment_node || assignment.node

            # Shorthand assignments always use their arguments
            next false if assignment_node.shorthand_asgn?
            next false unless assignment_node.parent

            node_within_block_or_conditional =
              node_within_block_or_conditional?(assignment_node.parent, argument.scope.node)

            unless uses_var?(assignment_node, argument.name)
              # It's impossible to decide whether a branch or block is executed,
              # so the precise reassignment location is undecidable.
              next false if node_within_block_or_conditional

              yield(assignment.node, location_known)
              break
            end

            location_known
          end
        end

        def reference_pos(node)
          node = node.parent if node.parent.masgn_type?

          node.source_range.begin_pos
        end

        # Check whether the given node is nested into block or conditional.
        #
        def node_within_block_or_conditional?(node, stop_search_node)
          return false if node == stop_search_node

          node.conditional? || node.block_type? ||
            node_within_block_or_conditional?(node.parent, stop_search_node)
        end

        # Get argument references without assignments' references
        #
        def argument_references(argument)
          assignment_references = argument.assignments.flat_map(&:references).map(&:source_range)

          argument.references.reject do |ref|
            next false unless ref.explicit?

            assignment_references.include?(ref.node.source_range)
          end
        end

        def ignore_implicit_references?
          cop_config['IgnoreImplicitReferences']
        end
      end
    end
  end
end
