# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of the class/module name instead of
      # self, when defining class/module methods.
      #
      # @example
      #   # bad
      #   class SomeClass
      #     def SomeClass.class_method
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   class SomeClass
      #     def self.class_method
      #       # ...
      #     end
      #   end
      class ClassMethods < Base
        extend AutoCorrector

        MSG = 'Use `self.%<method>s` instead of `%<class>s.%<method>s`.'

        def on_class(node)
          return unless node.body

          if node.body.defs_type?
            check_defs(node.identifier, node.body)
          elsif node.body.begin_type?
            node.body.each_child_node(:defs) { |def_node| check_defs(node.identifier, def_node) }
          end
        end
        alias on_module on_class

        private

        def check_defs(name, node)
          # check if the class/module name matches the definee for the defs node
          return unless name == node.receiver

          message = format(MSG, method: node.method_name, class: name.source)

          add_offense(node.receiver.loc.name, message: message) do |corrector|
            corrector.replace(node.receiver, 'self')
          end
        end
      end
    end
  end
end
