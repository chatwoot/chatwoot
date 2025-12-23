# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of `Array()` instead of explicit `Array` check or `[*var]`.
      #
      # The cop is disabled by default due to safety concerns.
      #
      # @safety
      #   This cop is unsafe because a false positive may occur if
      #   the argument of `Array()` is (or could be) nil or depending
      #   on how the argument is handled by `Array()` (which can be
      #   different than just wrapping the argument in an array).
      #
      #   For example:
      #
      #   [source,ruby]
      #   ----
      #   [nil]             #=> [nil]
      #   Array(nil)        #=> []
      #
      #   [{a: 'b'}]        #= [{a: 'b'}]
      #   Array({a: 'b'})   #=> [[:a, 'b']]
      #
      #   [Time.now]        #=> [#<Time ...>]
      #   Array(Time.now)   #=> [14, 16, 14, 16, 9, 2021, 4, 259, true, "EDT"]
      #   ----
      #
      # @example
      #   # bad
      #   paths = [paths] unless paths.is_a?(Array)
      #   paths.each { |path| do_something(path) }
      #
      #   # bad (always creates a new Array instance)
      #   [*paths].each { |path| do_something(path) }
      #
      #   # good (and a bit more readable)
      #   Array(paths).each { |path| do_something(path) }
      #
      class ArrayCoercion < Base
        extend AutoCorrector

        SPLAT_MSG = 'Use `Array(%<arg>s)` instead of `[*%<arg>s]`.'
        CHECK_MSG = 'Use `Array(%<arg>s)` instead of explicit `Array` check.'

        # @!method array_splat?(node)
        def_node_matcher :array_splat?, <<~PATTERN
          (array (splat $_))
        PATTERN

        # @!method unless_array?(node)
        def_node_matcher :unless_array?, <<~PATTERN
          (if
            (send
              (lvar $_) :is_a?
              (const nil? :Array)) nil?
            (lvasgn $_
              (array
                (lvar $_))))
        PATTERN

        def on_array(node)
          return unless node.square_brackets?

          array_splat?(node) do |arg_node|
            message = format(SPLAT_MSG, arg: arg_node.source)
            add_offense(node, message: message) do |corrector|
              corrector.replace(node, "Array(#{arg_node.source})")
            end
          end
        end

        def on_if(node)
          unless_array?(node) do |var_a, var_b, var_c|
            if var_a == var_b && var_c == var_b
              message = format(CHECK_MSG, arg: var_a)
              add_offense(node, message: message) do |corrector|
                corrector.replace(node, "#{var_a} = Array(#{var_a})")
              end
            end
          end
        end
      end
    end
  end
end
