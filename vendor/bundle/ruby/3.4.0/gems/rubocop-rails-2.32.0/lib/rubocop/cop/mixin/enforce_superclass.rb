# frozen_string_literal: true

module RuboCop
  module Cop # rubocop:disable Style/Documentation
    # The EnforceSuperclass module is also defined in `rubocop` (for backwards
    # compatibility), so here we remove it before (re)defining it, to avoid
    # warnings about methods in the module being redefined.
    remove_const(:EnforceSuperclass) if defined?(EnforceSuperclass)

    # Common functionality for enforcing a specific superclass.
    module EnforceSuperclass
      def self.included(base)
        base.def_node_matcher :class_definition, <<~PATTERN
          (class (const _ !:#{base::SUPERCLASS}) #{base::BASE_PATTERN} ...)
        PATTERN

        base.def_node_matcher :class_new_definition, <<~PATTERN
          [!^(casgn {nil? cbase} :#{base::SUPERCLASS} ...)
           !^^(casgn {nil? cbase} :#{base::SUPERCLASS} (block ...))
           (send (const {nil? cbase} :Class) :new #{base::BASE_PATTERN})]
        PATTERN
      end

      def on_class(node)
        class_definition(node) do
          register_offense(node.children[1])
        end
      end

      def on_send(node)
        class_new_definition(node) do
          register_offense(node.children.last)
        end
      end

      private

      def register_offense(offense_node)
        add_offense(offense_node) do |corrector|
          corrector.replace(offense_node, self.class::SUPERCLASS)
        end
      end
    end
  end
end
