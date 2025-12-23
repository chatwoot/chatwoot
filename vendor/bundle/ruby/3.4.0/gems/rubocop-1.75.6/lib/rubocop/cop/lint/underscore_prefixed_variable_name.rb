# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for underscore-prefixed variables that are actually
      # used.
      #
      # Since block keyword arguments cannot be arbitrarily named at call
      # sites, the `AllowKeywordBlockArguments` will allow use of underscore-
      # prefixed block keyword arguments.
      #
      # @example AllowKeywordBlockArguments: false (default)
      #
      #   # bad
      #
      #   [1, 2, 3].each do |_num|
      #     do_something(_num)
      #   end
      #
      #   query(:sales) do |_id:, revenue:, cost:|
      #     {_id: _id, profit: revenue - cost}
      #   end
      #
      #   # good
      #
      #   [1, 2, 3].each do |num|
      #     do_something(num)
      #   end
      #
      #   [1, 2, 3].each do |_num|
      #     do_something # not using `_num`
      #   end
      #
      # @example AllowKeywordBlockArguments: true
      #
      #   # good
      #
      #   query(:sales) do |_id:, revenue:, cost:|
      #     {_id: _id, profit: revenue - cost}
      #   end
      #
      class UnderscorePrefixedVariableName < Base
        MSG = 'Do not use prefix `_` for a variable that is used.'

        def self.joining_forces
          VariableForce
        end

        def after_leaving_scope(scope, _variable_table)
          scope.variables.each_value { |variable| check_variable(variable) }
        end

        def check_variable(variable)
          return unless variable.should_be_unused?
          return if variable.references.none?(&:explicit?)
          return if allowed_keyword_block_argument?(variable)

          node = variable.declaration_node

          location = if node.match_with_lvasgn_type?
                       node.children.first.source_range
                     else
                       node.loc.name
                     end

          add_offense(location)
        end

        private

        def allowed_keyword_block_argument?(variable)
          variable.block_argument? &&
            variable.keyword_argument? &&
            cop_config['AllowKeywordBlockArguments']
        end
      end
    end
  end
end
