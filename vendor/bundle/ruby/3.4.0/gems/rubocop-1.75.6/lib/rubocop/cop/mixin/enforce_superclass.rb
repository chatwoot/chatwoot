# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for enforcing a specific superclass.
    #
    # IMPORTANT: RuboCop core depended on this module when it supported Rails department.
    # Rails department has been extracted to RuboCop Rails gem.
    #
    # @deprecated This module is deprecated and will be removed by RuboCop 2.0.
    # It will not be updated to `RuboCop::Cop::Base` v1 API to maintain compatibility
    # with existing RuboCop Rails 2.8 or lower.
    #
    # @api private
    module EnforceSuperclass
      def self.included(base)
        warn Rainbow(
          '`RuboCop::Cop::EnforceSuperclass` is deprecated and will be removed in RuboCop 2.0. ' \
          'Please upgrade to RuboCop Rails 2.9 or newer to continue.'
        ).yellow

        # @!method class_definition(node)
        base.def_node_matcher :class_definition, <<~PATTERN
          (class (const _ !:#{base::SUPERCLASS}) #{base::BASE_PATTERN} ...)
        PATTERN

        # @!method class_new_definition(node)
        base.def_node_matcher :class_new_definition, <<~PATTERN
          [!^(casgn {nil? cbase} :#{base::SUPERCLASS} ...)
           !^^(casgn {nil? cbase} :#{base::SUPERCLASS} (block ...))
           (send (const {nil? cbase} :Class) :new #{base::BASE_PATTERN})]
        PATTERN
      end

      def on_class(node)
        class_definition(node) { add_offense(node.children[1]) }
      end

      def on_send(node)
        class_new_definition(node) { add_offense(node.children.last) }
      end
    end
  end
end
