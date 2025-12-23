# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for inheritance from `Data.define` to avoid creating the anonymous parent class.
      # Inheriting from `Data.define` adds a superfluous level in inheritance tree.
      #
      # @safety
      #   Autocorrection is unsafe because it will change the inheritance
      #   tree (e.g. return value of `Module#ancestors`) of the constant.
      #
      # @example
      #   # bad
      #   class Person < Data.define(:first_name, :last_name)
      #     def age
      #       42
      #     end
      #   end
      #
      #   Person.ancestors
      #   # => [Person, #<Class:0x000000010b4e14a0>, Data, (...)]
      #
      #   # good
      #   Person = Data.define(:first_name, :last_name) do
      #     def age
      #       42
      #     end
      #   end
      #
      #   Person.ancestors
      #   # => [Person, Data, (...)]
      class DataInheritance < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = "Don't extend an instance initialized by `Data.define`. " \
              'Use a block to customize the class.'

        minimum_target_ruby_version 3.2

        def on_class(node)
          return unless data_define?(node.parent_class)

          add_offense(node.parent_class) do |corrector|
            corrector.remove(range_with_surrounding_space(node.loc.keyword, newlines: false))
            corrector.replace(node.loc.operator, '=')

            correct_parent(node.parent_class, corrector)
          end
        end

        # @!method data_define?(node)
        def_node_matcher :data_define?, <<~PATTERN
          {(send (const {nil? cbase} :Data) :define ...)
           (block (send (const {nil? cbase} :Data) :define ...) ...)}
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

        def range_for_empty_class_body(class_node, data_define)
          if class_node.single_line?
            range_between(data_define.source_range.end_pos, class_node.source_range.end_pos)
          else
            range_by_whole_lines(class_node.loc.end, include_final_newline: true)
          end
        end
      end
    end
  end
end
