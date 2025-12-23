# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Common functionality for cops handling unused arguments.
      module UnusedArgument
        extend NodePattern::Macros

        def after_leaving_scope(scope, _variable_table)
          scope.variables.each_value { |variable| check_argument(variable) }
        end

        private

        def check_argument(variable)
          return if variable.should_be_unused?
          return if variable.referenced?

          message = message(variable)

          add_offense(variable.declaration_node.loc.name, message: message) do |corrector|
            autocorrect(corrector, variable.declaration_node)
          end
        end
      end
    end
  end
end
