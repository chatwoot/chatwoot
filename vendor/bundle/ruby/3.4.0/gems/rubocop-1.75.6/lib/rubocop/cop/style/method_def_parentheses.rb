# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for parentheses around the arguments in method
      # definitions. Both instance and class/singleton methods are checked.
      #
      # Regardless of style, parentheses are necessary for:
      #
      # 1. Endless methods
      # 2. Argument lists containing a `forward-arg` (`...`)
      # 3. Argument lists containing an anonymous rest arguments forwarding (`*`)
      # 4. Argument lists containing an anonymous keyword rest arguments forwarding (`**`)
      # 5. Argument lists containing an anonymous block forwarding (`&`)
      #
      # Removing the parens would be a syntax error here.
      #
      # @example EnforcedStyle: require_parentheses (default)
      #   # The `require_parentheses` style requires method definitions
      #   # to always use parentheses
      #
      #   # bad
      #   def bar num1, num2
      #     num1 + num2
      #   end
      #
      #   def foo descriptive_var_name,
      #           another_descriptive_var_name,
      #           last_descriptive_var_name
      #     do_something
      #   end
      #
      #   # good
      #   def bar(num1, num2)
      #     num1 + num2
      #   end
      #
      #   def foo(descriptive_var_name,
      #           another_descriptive_var_name,
      #           last_descriptive_var_name)
      #     do_something
      #   end
      #
      # @example EnforcedStyle: require_no_parentheses
      #   # The `require_no_parentheses` style requires method definitions
      #   # to never use parentheses
      #
      #   # bad
      #   def bar(num1, num2)
      #     num1 + num2
      #   end
      #
      #   def foo(descriptive_var_name,
      #           another_descriptive_var_name,
      #           last_descriptive_var_name)
      #     do_something
      #   end
      #
      #   # good
      #   def bar num1, num2
      #     num1 + num2
      #   end
      #
      #   def foo descriptive_var_name,
      #           another_descriptive_var_name,
      #           last_descriptive_var_name
      #     do_something
      #   end
      #
      # @example EnforcedStyle: require_no_parentheses_except_multiline
      #   # The `require_no_parentheses_except_multiline` style prefers no
      #   # parentheses when method definition arguments fit on single line,
      #   # but prefers parentheses when arguments span multiple lines.
      #
      #   # bad
      #   def bar(num1, num2)
      #     num1 + num2
      #   end
      #
      #   def foo descriptive_var_name,
      #           another_descriptive_var_name,
      #           last_descriptive_var_name
      #     do_something
      #   end
      #
      #   # good
      #   def bar num1, num2
      #     num1 + num2
      #   end
      #
      #   def foo(descriptive_var_name,
      #           another_descriptive_var_name,
      #           last_descriptive_var_name)
      #     do_something
      #   end
      class MethodDefParentheses < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG_PRESENT = 'Use def without parentheses.'
        MSG_MISSING = 'Use def with parentheses when there are parameters.'

        def on_def(node)
          return if forced_parentheses?(node)

          args = node.arguments

          if require_parentheses?(args)
            if arguments_without_parentheses?(node)
              missing_parentheses(node)
            else
              correct_style_detected
            end
          elsif parentheses?(args)
            unwanted_parentheses(args)
          else
            correct_style_detected
          end
        end
        alias on_defs on_def

        private

        def correct_arguments(arg_node, corrector)
          corrector.replace(arg_node.loc.begin, ' ')
          corrector.remove(arg_node.loc.end)
        end

        def forced_parentheses?(node)
          # Regardless of style, parentheses are necessary for:
          # 1. Endless methods
          # 2. Argument lists containing a `forward-arg` (`...`)
          # 3. Argument lists containing an anonymous rest arguments forwarding (`*`)
          # 4. Argument lists containing an anonymous keyword rest arguments forwarding (`**`)
          # 5. Argument lists containing an anonymous block forwarding (`&`)
          # Removing the parens would be a syntax error here.
          node.endless? || anonymous_arguments?(node)
        end

        def require_parentheses?(args)
          style == :require_parentheses ||
            (style == :require_no_parentheses_except_multiline && args.multiline?)
        end

        def arguments_without_parentheses?(node)
          node.arguments? && !parentheses?(node.arguments)
        end

        def missing_parentheses(node)
          location = node.arguments.source_range

          add_offense(location, message: MSG_MISSING) do |corrector|
            add_parentheses(node.arguments, corrector)

            unexpected_style_detected 'require_no_parentheses'
          end
        end

        def unwanted_parentheses(args)
          add_offense(args, message: MSG_PRESENT) do |corrector|
            # offense is registered on args node when parentheses are unwanted
            correct_arguments(args, corrector)
            unexpected_style_detected 'require_parentheses'
          end
        end

        def anonymous_arguments?(node)
          return true if node.arguments.any? do |arg|
            arg.type?(:forward_arg, :restarg, :kwrestarg)
          end
          return false unless (last_argument = node.last_argument)

          last_argument.blockarg_type? && last_argument.name.nil?
        end
      end
    end
  end
end
