# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Checks for `OpenStruct.new` calls.
      # Instantiation of an `OpenStruct` invalidates
      # Ruby global method cache as it causes dynamic method
      # definition during program runtime.
      # This could have an effect on performance,
      # especially in case of single-threaded
      # applications with multiple `OpenStruct` instantiations.
      #
      # @safety
      #   This cop is unsafe because `OpenStruct.new` and `Struct.new`
      #   are not equivalent.
      #
      # @example
      #   # bad
      #   class MyClass
      #     def my_method
      #       OpenStruct.new(my_key1: 'my_value1', my_key2: 'my_value2')
      #     end
      #   end
      #
      #   # good
      #   class MyClass
      #     MyStruct = Struct.new(:my_key1, :my_key2)
      #     def my_method
      #       MyStruct.new('my_value1', 'my_value2')
      #     end
      #   end
      #
      class OpenStruct < Base
        MSG = 'Consider using `Struct` over `OpenStruct` to optimize the performance.'
        RESTRICT_ON_SEND = %i[new].freeze

        def_node_matcher :open_struct, <<~PATTERN
          (send (const {nil? cbase} :OpenStruct) :new ...)
        PATTERN

        def on_send(node)
          open_struct(node) do
            add_offense(node.loc.selector)
          end
        end
      end
    end
  end
end
