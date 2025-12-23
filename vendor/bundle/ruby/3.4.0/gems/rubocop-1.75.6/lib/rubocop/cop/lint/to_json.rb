# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks to make sure `#to_json` includes an optional argument.
      # When overriding `#to_json`, callers may invoke JSON
      # generation via `JSON.generate(your_obj)`.  Since `JSON#generate` allows
      # for an optional argument, your method should too.
      #
      # @example
      #   class Point
      #     attr_reader :x, :y
      #
      #     # bad, incorrect arity
      #     def to_json
      #       JSON.generate([x, y])
      #     end
      #
      #     # good, preserving args
      #     def to_json(*args)
      #       JSON.generate([x, y], *args)
      #     end
      #
      #     # good, discarding args
      #     def to_json(*_args)
      #       JSON.generate([x, y])
      #     end
      #   end
      #
      class ToJSON < Base
        extend AutoCorrector

        MSG = '`#to_json` requires an optional argument to be parsable via JSON.generate(obj).'

        def on_def(node)
          return unless node.method?(:to_json) && node.arguments.empty?

          add_offense(node) do |corrector|
            # The following used `*_args` because `to_json(*args)` has
            # an offense of `Lint/UnusedMethodArgument` cop if `*args`
            # is not used.
            corrector.insert_after(node.loc.name, '(*_args)')
          end
        end
      end
    end
  end
end
