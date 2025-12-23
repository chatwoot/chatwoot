# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks that method names are checked using `method?` method.
      #
      # @example
      #   # bad
      #   node.method_name == :do_something
      #
      #   # good
      #   node.method?(:do_something)
      #
      #   # bad
      #   node.method_name != :do_something
      #
      #   # good
      #   !node.method?(:do_something)
      #
      class MethodNameEqual < Base
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead.'
        RESTRICT_ON_SEND = %i[== !=].freeze

        # @!method method_name(node)
        def_node_matcher :method_name, <<~PATTERN
          (send
            (send
              (...) :method_name) {:== :!=}
            $_)
        PATTERN

        def on_send(node)
          method_name(node) do |method_name_arg|
            bang = node.method?(:!=) ? '!' : ''
            prefer = "#{bang}#{node.receiver.receiver.source}.method?(#{method_name_arg.source})"
            message = format(MSG, prefer: prefer)

            add_offense(node, message: message) do |corrector|
              corrector.replace(node, prefer)
            end
          end
        end
      end
    end
  end
end
