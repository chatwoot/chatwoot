# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks the args passed to `fail` and `raise`.
      #
      # Exploded style (default) enforces passing the exception class and message
      # arguments separately, rather than constructing an instance of the error.
      #
      # Compact style enforces constructing an error instance.
      #
      # Both styles allow passing just a message, or an error instance when there is more
      # than one argument.
      #
      # The exploded style has an `AllowedCompactTypes` configuration
      # option that takes an `Array` of exception name Strings.
      #
      # @safety
      #   This cop is unsafe because `raise Foo` calls `Foo.exception`, not `Foo.new`.
      #
      # @example EnforcedStyle: exploded (default)
      #   # bad
      #   raise StandardError.new('message')
      #
      #   # good
      #   raise StandardError, 'message'
      #   fail 'message'
      #   raise MyCustomError
      #   raise MyCustomError.new(arg1, arg2, arg3)
      #   raise MyKwArgError.new(key1: val1, key2: val2)
      #
      #   # With `AllowedCompactTypes` set to ['MyWrappedError']
      #   raise MyWrappedError.new(obj)
      #   raise MyWrappedError.new(obj), 'message'
      #
      # @example EnforcedStyle: compact
      #   # bad
      #   raise StandardError, 'message'
      #   raise RuntimeError, arg1, arg2, arg3
      #
      #   # good
      #   raise StandardError.new('message')
      #   raise MyCustomError
      #   raise MyCustomError.new(arg1, arg2, arg3)
      #   fail 'message'
      class RaiseArgs < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        EXPLODED_MSG = 'Provide an exception class and message as arguments to `%<method>s`.'
        COMPACT_MSG = 'Provide an exception object as an argument to `%<method>s`.'
        ACCEPTABLE_ARG_TYPES = %i[
          hash forwarded_restarg splat forwarded_restarg forwarded_args
        ].freeze

        RESTRICT_ON_SEND = %i[raise fail].freeze

        def on_send(node)
          return unless node.command?(:raise) || node.command?(:fail)

          case style
          when :compact
            check_compact(node)
          when :exploded
            check_exploded(node)
          end
        end

        private

        def correction_compact_to_exploded(node)
          exception_node, _new, message_node = *node.first_argument

          arguments = [exception_node, message_node].compact.map(&:source).join(', ')

          if node.parent && requires_parens?(node.parent)
            "#{node.method_name}(#{arguments})"
          else
            "#{node.method_name} #{arguments}"
          end
        end

        def correction_exploded_to_compact(node)
          exception_node, *message_nodes = *node.arguments
          return if message_nodes.size > 1

          argument = message_nodes.first.source
          exception_class = exception_node.receiver&.source || exception_node.source

          if node.parent && requires_parens?(node.parent)
            "#{node.method_name}(#{exception_class}.new(#{argument}))"
          else
            "#{node.method_name} #{exception_class}.new(#{argument})"
          end
        end

        def check_compact(node)
          if node.arguments.size > 1
            exception = node.first_argument
            return if exception.send_type? && exception.first_argument&.hash_type?

            add_offense(node, message: format(COMPACT_MSG, method: node.method_name)) do |corrector|
              replacement = correction_exploded_to_compact(node)

              corrector.replace(node, replacement)
              opposite_style_detected
            end
          else
            correct_style_detected
          end
        end

        def check_exploded(node)
          return correct_style_detected unless node.arguments.one?

          first_arg = node.first_argument

          return if !use_new_method?(first_arg) || acceptable_exploded_args?(first_arg.arguments)

          return if allowed_non_exploded_type?(first_arg)

          add_offense(node, message: format(EXPLODED_MSG, method: node.method_name)) do |corrector|
            replacement = correction_compact_to_exploded(node)

            corrector.replace(node, replacement)
            opposite_style_detected
          end
        end

        def use_new_method?(first_arg)
          first_arg.send_type? && first_arg.receiver && first_arg.method?(:new)
        end

        def acceptable_exploded_args?(args)
          # Allow code like `raise Ex.new(arg1, arg2)`.
          return true if args.size > 1

          # Disallow zero arguments.
          return false if args.empty?

          arg = args.first

          # Allow nodes that may forward more than one argument
          ACCEPTABLE_ARG_TYPES.include?(arg.type)
        end

        def allowed_non_exploded_type?(arg)
          type = arg.receiver.const_name

          Array(cop_config['AllowedCompactTypes']).include?(type)
        end

        def requires_parens?(parent)
          parent.operator_keyword? || (parent.if_type? && parent.ternary?)
        end
      end
    end
  end
end
