# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Flags uses of `OpenStruct`, as it is now officially discouraged
      # to be used for performance, version compatibility, and potential security issues.
      #
      # @safety
      #   Note that this cop may flag false positives; for instance, the following legal
      #   use of a hand-rolled `OpenStruct` type would be considered an offense:
      #
      #   [source,ruby]
      #   -----
      #   module MyNamespace
      #     class OpenStruct # not the OpenStruct we're looking for
      #     end
      #
      #     def new_struct
      #       OpenStruct.new # resolves to MyNamespace::OpenStruct
      #     end
      #   end
      #   -----
      #
      # @example
      #
      #   # bad
      #   point = OpenStruct.new(x: 0, y: 1)
      #
      #   # good
      #   Point = Struct.new(:x, :y)
      #   point = Point.new(0, 1)
      #
      #   # also good
      #   point = { x: 0, y: 1 }
      #
      #   # bad
      #   test_double = OpenStruct.new(a: 'b')
      #
      #   # good (assumes test using rspec-mocks)
      #   test_double = double
      #   allow(test_double).to receive(:a).and_return('b')
      #
      class OpenStructUse < Base
        MSG = 'Avoid using `OpenStruct`; use `Struct`, `Hash`, a class or test doubles instead.'

        # @!method uses_open_struct?(node)
        def_node_matcher :uses_open_struct?, <<~PATTERN
          (const {nil? (cbase)} :OpenStruct)
        PATTERN

        def on_const(node)
          return unless uses_open_struct?(node)
          return if custom_class_or_module_definition?(node)

          add_offense(node)
        end

        private

        def custom_class_or_module_definition?(node)
          parent = node.parent

          parent.type?(:class, :module) && node.left_siblings.empty?
        end
      end
    end
  end
end
