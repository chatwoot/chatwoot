# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks if each_with_object is called with an immutable
      # argument. Since the argument is the object that the given block shall
      # make calls on to build something based on the enumerable that
      # each_with_object iterates over, an immutable argument makes no sense.
      # It's definitely a bug.
      #
      # @example
      #
      #   # bad
      #   sum = numbers.each_with_object(0) { |e, a| a += e }
      #
      #   # good
      #   num = 0
      #   sum = numbers.each_with_object(num) { |e, a| a += e }
      class EachWithObjectArgument < Base
        MSG = 'The argument to each_with_object cannot be immutable.'
        RESTRICT_ON_SEND = %i[each_with_object].freeze

        # @!method each_with_object?(node)
        def_node_matcher :each_with_object?, <<~PATTERN
          (call _ :each_with_object $_)
        PATTERN

        def on_send(node)
          each_with_object?(node) do |arg|
            return unless arg.immutable_literal?

            add_offense(node)
          end
        end
        alias on_csend on_send
      end
    end
  end
end
