# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for string conversion in string interpolation, `print`, `puts`, and `warn` arguments,
      # which is redundant.
      #
      # @example
      #
      #   # bad
      #   "result is #{something.to_s}"
      #   print something.to_s
      #   puts something.to_s
      #   warn something.to_s
      #
      #   # good
      #   "result is #{something}"
      #   print something
      #   puts something
      #   warn something
      #
      class RedundantStringCoercion < Base
        include Interpolation
        extend AutoCorrector

        MSG_DEFAULT = 'Redundant use of `Object#to_s` in %<context>s.'
        MSG_SELF = 'Use `self` instead of `Object#to_s` in %<context>s.'
        RESTRICT_ON_SEND = %i[print puts warn].freeze

        # @!method to_s_without_args?(node)
        def_node_matcher :to_s_without_args?, '(call _ :to_s)'

        def on_interpolation(begin_node)
          final_node = begin_node.children.last

          return unless to_s_without_args?(final_node)

          register_offense(final_node, 'interpolation')
        end

        def on_send(node)
          return if node.receiver

          node.each_child_node(:call) do |child|
            next if !child.method?(:to_s) || child.arguments.any?

            register_offense(child, "`#{node.method_name}`")
          end
        end

        private

        def register_offense(node, context)
          receiver = node.receiver
          template = receiver ? MSG_DEFAULT : MSG_SELF
          message = format(template, context: context)

          add_offense(node.loc.selector, message: message) do |corrector|
            replacement = receiver ? receiver.source : 'self'

            corrector.replace(node, replacement)
          end
        end
      end
    end
  end
end
