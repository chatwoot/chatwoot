# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Checks method parameter names for how descriptive they
      # are. It is highly configurable.
      #
      # The `MinNameLength` config option takes an integer. It represents
      # the minimum amount of characters the name must be. Its default is 3.
      # The `AllowNamesEndingInNumbers` config option takes a boolean. When
      # set to false, this cop will register offenses for names ending with
      # numbers. Its default is false. The `AllowedNames` config option
      # takes an array of permitted names that will never register an
      # offense. The `ForbiddenNames` config option takes an array of
      # restricted names that will always register an offense.
      #
      # @example
      #   # bad
      #   def bar(varOne, varTwo)
      #     varOne + varTwo
      #   end
      #
      #   # With `AllowNamesEndingInNumbers` set to false
      #   def foo(num1, num2)
      #     num1 * num2
      #   end
      #
      #   # With `MinNameLength` set to number greater than 1
      #   def baz(a, b, c)
      #     do_stuff(a, b, c)
      #   end
      #
      #   # good
      #   def bar(thud, fred)
      #     thud + fred
      #   end
      #
      #   def foo(speed, distance)
      #     speed * distance
      #   end
      #
      #   def baz(age_a, height_b, gender_c)
      #     do_stuff(age_a, height_b, gender_c)
      #   end
      class MethodParameterName < Base
        include UncommunicativeName

        def on_def(node)
          return unless node.arguments?

          check(node, node.arguments)
        end
        alias on_defs on_def
      end
    end
  end
end
