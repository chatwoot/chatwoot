# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for inheritance from `Struct.new`. Inheriting from `Struct.new`
      # adds a superfluous level in inheritance tree.
      #
      # @safety
      #   Autocorrection is unsafe because it will change the inheritance
      #   tree (e.g. return value of `Module#ancestors`) of the constant.
      #
      # @example
      #   # bad
      #   class Person < Struct.new(:first_name, :last_name)
      #     def age
      #       42
      #     end
      #   end
      #
      #   Person.ancestors
      #   # => [Person, #<Class:0x000000010b4e14a0>, Struct, (...)]
      #
      #   # good
      #   Person = Struct.new(:first_name, :last_name) do
      #     def age
      #       42
      #     end
      #   end
      #
      #   Person.ancestors
      #   # => [Person, Struct, (...)]
      class StructInheritance < Base
        include RangeHelp
        extend AutoCorrector

        MSG = "Don't extend an instance initialized by `Struct.new`. " \
              'Use a block to customize the struct.'

        def on_class(node)
          return unless struct_constructor?(node.parent_class)

          add_offense(node.parent_class) do |corrector|
            corrector.remove(range_with_surrounding_space(node.loc.keyword, newlines: false))
            corrector.replace(node.loc.operator, '=')

            correct_parent(node.parent_class, corrector)
          end
        end

        # @!method struct_constructor?(node)
        def_node_matcher :struct_constructor?, <<~PATTERN
          {(send (const {nil? cbase} :Struct) :new ...)
           (block (send (const {nil? cbase} :Struct) :new ...) ...)}
        PATTERN

        private

        def correct_parent(parent, corrector)
          if parent.block_type?
            corrector.remove(range_with_surrounding_space(parent.loc.end, newlines: false))
          elsif (class_node = parent.parent).body.nil?
            corrector.remove(range_for_empty_class_body(class_node, parent))
          else
            corrector.insert_after(parent, ' do')
          end
        end

        def range_for_empty_class_body(class_node, struct_new)
          if class_node.single_line?
            range_between(struct_new.source_range.end_pos, class_node.source_range.end_pos)
          else
            range_by_whole_lines(class_node.loc.end, include_final_newline: true)
          end
        end
      end
    end
  end
end
