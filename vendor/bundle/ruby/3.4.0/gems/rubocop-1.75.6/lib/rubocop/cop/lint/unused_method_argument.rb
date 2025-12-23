# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for unused method arguments.
      #
      # @example
      #   # bad
      #   def some_method(used, unused, _unused_but_allowed)
      #     puts used
      #   end
      #
      #   # good
      #   def some_method(used, _unused, _unused_but_allowed)
      #     puts used
      #   end
      #
      # @example AllowUnusedKeywordArguments: false (default)
      #   # bad
      #   def do_something(used, unused: 42)
      #     used
      #   end
      #
      # @example AllowUnusedKeywordArguments: true
      #   # good
      #   def do_something(used, unused: 42)
      #     used
      #   end
      #
      # @example IgnoreEmptyMethods: true (default)
      #   # good
      #   def do_something(unused)
      #   end
      #
      # @example IgnoreEmptyMethods: false
      #   # bad
      #   def do_something(unused)
      #   end
      #
      # @example IgnoreNotImplementedMethods: true (default)
      #   # with default value of `NotImplementedExceptions: ['NotImplementedError']`
      #
      #   # good
      #   def do_something(unused)
      #     raise NotImplementedError
      #   end
      #
      #   def do_something_else(unused)
      #     fail "TODO"
      #   end
      #
      # @example IgnoreNotImplementedMethods: true
      #   # with `NotImplementedExceptions: ['AbstractMethodError']`
      #
      #   # good
      #   def do_something(unused)
      #     raise AbstractMethodError
      #   end
      #
      # @example IgnoreNotImplementedMethods: false
      #   # bad
      #   def do_something(unused)
      #     raise NotImplementedError
      #   end
      #
      #   def do_something_else(unused)
      #     fail "TODO"
      #   end
      class UnusedMethodArgument < Base
        include UnusedArgument
        extend AutoCorrector

        # @!method not_implemented?(node)
        def_node_matcher :not_implemented?, <<~PATTERN
          {(send nil? :raise #allowed_exception_class? ...)
           (send nil? :fail ...)}
        PATTERN

        def self.autocorrect_incompatible_with
          [Style::ExplicitBlockArgument]
        end

        def self.joining_forces
          VariableForce
        end

        private

        def autocorrect(corrector, node)
          UnusedArgCorrector.correct(corrector, processed_source, node)
        end

        def check_argument(variable)
          return unless variable.method_argument?
          return if variable.keyword_argument? && cop_config['AllowUnusedKeywordArguments']
          return if ignored_method?(variable.scope.node.body)

          super
        end

        def ignored_method?(body)
          (cop_config['IgnoreEmptyMethods'] && body.nil?) ||
            (cop_config['IgnoreNotImplementedMethods'] && not_implemented?(body))
        end

        def message(variable)
          message = +"Unused method argument - `#{variable.name}`."

          unless variable.keyword_argument?
            message << " If it's necessary, use `_` or `_#{variable.name}` " \
                       "as an argument name to indicate that it won't be used. " \
                       "If it's unnecessary, remove it."
          end

          scope = variable.scope
          all_arguments = scope.variables.each_value.select(&:method_argument?)

          if all_arguments.none?(&:referenced?)
            message << " You can also write as `#{scope.name}(*)` " \
                       'if you want the method to accept any arguments ' \
                       "but don't care about them."
          end

          message
        end

        def allowed_exception_class?(node)
          return false unless node.const_type?

          allowed_class_names = Array(cop_config.fetch('NotImplementedExceptions', []))
          allowed_class_names.include?(node.const_name)
        end
      end
    end
  end
end
