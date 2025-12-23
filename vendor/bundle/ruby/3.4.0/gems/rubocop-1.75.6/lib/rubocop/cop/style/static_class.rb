# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for places where classes with only class methods can be
      # replaced with a module. Classes should be used only when it makes sense to create
      # instances out of them.
      #
      # @safety
      #   This cop is unsafe, because it is possible that this class is a parent
      #   for some other subclass, monkey-patched with instance methods or
      #   a dummy instance is instantiated from it somewhere.
      #
      # @example
      #   # bad
      #   class SomeClass
      #     def self.some_method
      #       # body omitted
      #     end
      #
      #     def self.some_other_method
      #       # body omitted
      #     end
      #   end
      #
      #   # good
      #   module SomeModule
      #     module_function
      #
      #     def some_method
      #       # body omitted
      #     end
      #
      #     def some_other_method
      #       # body omitted
      #     end
      #   end
      #
      #   # good - has instance method
      #   class SomeClass
      #     def instance_method; end
      #     def self.class_method; end
      #   end
      #
      class StaticClass < Base
        include RangeHelp
        include VisibilityHelp
        extend AutoCorrector

        MSG = 'Prefer modules to classes with only class methods.'

        def on_class(class_node)
          return if class_node.parent_class
          return unless class_convertible_to_module?(class_node)

          add_offense(class_node) do |corrector|
            autocorrect(corrector, class_node)
          end
        end

        private

        def autocorrect(corrector, class_node)
          corrector.replace(class_node.loc.keyword, 'module')
          corrector.insert_after(class_node.loc.name, "\nmodule_function\n")

          class_elements(class_node).each do |node|
            if node.defs_type?
              autocorrect_def(corrector, node)
            elsif node.sclass_type?
              autocorrect_sclass(corrector, node)
            end
          end
        end

        def autocorrect_def(corrector, node)
          corrector.remove(
            range_between(node.receiver.source_range.begin_pos, node.loc.name.begin_pos)
          )
        end

        def autocorrect_sclass(corrector, node)
          corrector.remove(
            range_between(node.loc.keyword.begin_pos, node.identifier.source_range.end_pos)
          )
          corrector.remove(node.loc.end)
        end

        def class_convertible_to_module?(class_node)
          nodes = class_elements(class_node)
          return false if nodes.empty?

          nodes.all? do |node|
            (node_visibility(node) == :public && node.defs_type?) ||
              sclass_convertible_to_module?(node) ||
              node.equals_asgn? ||
              extend_call?(node)
          end
        end

        def extend_call?(node)
          node.send_type? && node.method?(:extend)
        end

        def sclass_convertible_to_module?(node)
          return false unless node.sclass_type?

          class_elements(node).all? do |child|
            node_visibility(child) == :public && (child.def_type? || child.equals_asgn?)
          end
        end

        def class_elements(class_node)
          class_def = class_node.body

          if !class_def
            []
          elsif class_def.begin_type?
            class_def.children
          else
            [class_def]
          end
        end
      end
    end
  end
end
