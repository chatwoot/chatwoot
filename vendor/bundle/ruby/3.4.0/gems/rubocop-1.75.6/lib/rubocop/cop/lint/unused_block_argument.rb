# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for unused block arguments.
      #
      # @example
      #   # bad
      #   do_something do |used, unused|
      #     puts used
      #   end
      #
      #   do_something do |bar|
      #     puts :foo
      #   end
      #
      #   define_method(:foo) do |bar|
      #     puts :baz
      #   end
      #
      #   # good
      #   do_something do |used, _unused|
      #     puts used
      #   end
      #
      #   do_something do
      #     puts :foo
      #   end
      #
      #   define_method(:foo) do |_bar|
      #     puts :baz
      #   end
      #
      # @example IgnoreEmptyBlocks: true (default)
      #   # good
      #   do_something { |unused| }
      #
      # @example IgnoreEmptyBlocks: false
      #   # bad
      #   do_something { |unused| }
      #
      # @example AllowUnusedKeywordArguments: false (default)
      #   # bad
      #   do_something do |unused: 42|
      #     foo
      #   end
      #
      # @example AllowUnusedKeywordArguments: true
      #   # good
      #   do_something do |unused: 42|
      #     foo
      #   end
      #
      class UnusedBlockArgument < Base
        include UnusedArgument
        extend AutoCorrector

        def self.joining_forces
          VariableForce
        end

        private

        def autocorrect(corrector, node)
          UnusedArgCorrector.correct(corrector, processed_source, node)
        end

        def check_argument(variable)
          return if allowed_block?(variable) ||
                    allowed_keyword_argument?(variable) ||
                    used_block_local?(variable)

          super
        end

        def used_block_local?(variable)
          variable.explicit_block_local_variable? && !variable.assignments.empty?
        end

        def allowed_block?(variable)
          !variable.block_argument? || (ignore_empty_blocks? && empty_block?(variable))
        end

        def allowed_keyword_argument?(variable)
          variable.keyword_argument? && allow_unused_keyword_arguments?
        end

        def message(variable)
          message = "Unused #{variable_type(variable)} - `#{variable.name}`."

          if variable.explicit_block_local_variable?
            message
          else
            augment_message(message, variable)
          end
        end

        def augment_message(message, variable)
          scope = variable.scope
          all_arguments = scope.variables.each_value.select(&:block_argument?)

          augmentation = if scope.node.lambda?
                           message_for_lambda(variable, all_arguments)
                         else
                           message_for_normal_block(variable, all_arguments)
                         end

          [message, augmentation].join(' ')
        end

        def variable_type(variable)
          if variable.explicit_block_local_variable?
            'block local variable'
          else
            'block argument'
          end
        end

        def message_for_normal_block(variable, all_arguments)
          if all_arguments.none?(&:referenced?) && !define_method_call?(variable)
            if all_arguments.count > 1
              "You can omit all the arguments if you don't care about them."
            else
              "You can omit the argument if you don't care about it."
            end
          else
            message_for_underscore_prefix(variable)
          end
        end

        def message_for_lambda(variable, all_arguments)
          message = message_for_underscore_prefix(variable)

          if all_arguments.none?(&:referenced?)
            proc_message = 'Also consider using a proc without arguments ' \
                           'instead of a lambda if you want it ' \
                           "to accept any arguments but don't care about them."
          end

          [message, proc_message].compact.join(' ')
        end

        def message_for_underscore_prefix(variable)
          "If it's necessary, use `_` or `_#{variable.name}` " \
            "as an argument name to indicate that it won't be used."
        end

        def define_method_call?(variable)
          call, = *variable.scope.node
          _, method, = *call

          method == :define_method
        end

        def empty_block?(variable)
          _send, _args, body = *variable.scope.node

          body.nil?
        end

        def allow_unused_keyword_arguments?
          cop_config['AllowUnusedKeywordArguments']
        end

        def ignore_empty_blocks?
          cop_config['IgnoreEmptyBlocks']
        end
      end
    end
  end
end
