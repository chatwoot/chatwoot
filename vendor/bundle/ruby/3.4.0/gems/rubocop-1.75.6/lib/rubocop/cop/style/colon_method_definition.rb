# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for class methods that are defined using the `::`
      # operator instead of the `.` operator.
      #
      # @example
      #   # bad
      #   class Foo
      #     def self::bar
      #     end
      #   end
      #
      #   # good
      #   class Foo
      #     def self.bar
      #     end
      #   end
      #
      class ColonMethodDefinition < Base
        extend AutoCorrector

        MSG = 'Do not use `::` for defining class methods.'

        def on_defs(node)
          return unless node.loc.operator.source == '::'

          add_offense(node.loc.operator) do |corrector|
            corrector.replace(node.loc.operator, '.')
          end
        end
      end
    end
  end
end
