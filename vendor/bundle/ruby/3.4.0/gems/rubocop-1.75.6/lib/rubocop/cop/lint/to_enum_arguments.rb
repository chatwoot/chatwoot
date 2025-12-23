# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Ensures that `to_enum`/`enum_for`, called for the current method,
      # has correct arguments.
      #
      # @example
      #   # bad
      #   def foo(x, y = 1)
      #     return to_enum(__callee__, x) # `y` is missing
      #   end
      #
      #   # good
      #   def foo(x, y = 1)
      #     # Alternatives to `__callee__` are `__method__` and `:foo`.
      #     return to_enum(__callee__, x, y)
      #   end
      #
      #   # good
      #   def foo(x, y = 1)
      #     # It is also allowed if it is wrapped in some method like Sorbet.
      #     return to_enum(T.must(__callee__), x, y)
      #   end
      #
      class ToEnumArguments < Base
        MSG = 'Ensure you correctly provided all the arguments.'

        RESTRICT_ON_SEND = %i[to_enum enum_for].freeze

        # @!method enum_conversion_call?(node)
        def_node_matcher :enum_conversion_call?, <<~PATTERN
          (send {nil? self} {:to_enum :enum_for} $_ $...)
        PATTERN

        # @!method method_name?(node, name)
        def_node_matcher :method_name?, <<~PATTERN
          {(send nil? {:__method__ :__callee__}) (sym %1)}
        PATTERN

        # @!method passing_keyword_arg?(node, name)
        def_node_matcher :passing_keyword_arg?, <<~PATTERN
          (pair (sym %1) (lvar %1))
        PATTERN

        def on_send(node)
          def_node = node.each_ancestor(:any_def).first
          return unless def_node

          enum_conversion_call?(node) do |method_node, arguments|
            next if !method_name?(method_node, def_node.method_name) ||
                    arguments_match?(arguments, def_node)

            add_offense(node)
          end
        end

        private

        def arguments_match?(arguments, def_node)
          index = 0

          def_node.arguments.reject(&:blockarg_type?).all? do |def_arg|
            send_arg = arguments[index]
            case def_arg.type
            when :arg, :restarg, :optarg
              index += 1
            end

            send_arg && argument_match?(send_arg, def_arg)
          end
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        def argument_match?(send_arg, def_arg)
          def_arg_name = def_arg.children[0]

          case def_arg.type
          when :arg, :restarg
            send_arg.source == def_arg.source
          when :optarg
            send_arg.source == def_arg_name.to_s
          when :kwoptarg, :kwarg
            send_arg.hash_type? &&
              send_arg.pairs.any? { |pair| passing_keyword_arg?(pair, def_arg_name) }
          when :kwrestarg
            send_arg.each_child_node(:kwsplat, :forwarded_kwrestarg).any? do |child|
              child.source == def_arg.source
            end
          when :forward_arg
            send_arg.forwarded_args_type?
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      end
    end
  end
end
