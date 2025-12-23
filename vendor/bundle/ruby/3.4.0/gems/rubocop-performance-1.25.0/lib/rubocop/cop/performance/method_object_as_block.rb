# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where methods are converted to blocks, with the
      # use of `&method`, and passed as arguments to method calls.
      # It is faster to replace those with explicit blocks, calling those methods inside.
      #
      # @example
      #   # bad
      #   array.map(&method(:do_something))
      #   [1, 2, 3].each(&out.method(:puts))
      #
      #   # good
      #   array.map { |x| do_something(x) }
      #   [1, 2, 3].each { |x| out.puts(x) }
      #
      class MethodObjectAsBlock < Base
        MSG = 'Use block explicitly instead of block-passing a method object.'

        def_node_matcher :method_object_as_argument?, <<~PATTERN
          (^send (send _ :method sym))
        PATTERN

        def on_block_pass(node)
          add_offense(node) if method_object_as_argument?(node)
        end
      end
    end
  end
end
