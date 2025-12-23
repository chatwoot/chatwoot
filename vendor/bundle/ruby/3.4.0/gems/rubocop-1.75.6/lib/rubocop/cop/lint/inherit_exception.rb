# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Looks for error classes inheriting from `Exception`.
      # It is configurable to suggest using either `StandardError` (default) or
      # `RuntimeError` instead.
      #
      # @safety
      #   This cop's autocorrection is unsafe because `rescue` that omit
      #   exception class handle `StandardError` and its subclasses,
      #   but not `Exception` and its subclasses.
      #
      # @example EnforcedStyle: standard_error (default)
      #   # bad
      #
      #   class C < Exception; end
      #
      #   C = Class.new(Exception)
      #
      #   # good
      #
      #   class C < StandardError; end
      #
      #   C = Class.new(StandardError)
      #
      # @example EnforcedStyle: runtime_error
      #   # bad
      #
      #   class C < Exception; end
      #
      #   C = Class.new(Exception)
      #
      #   # good
      #
      #   class C < RuntimeError; end
      #
      #   C = Class.new(RuntimeError)
      class InheritException < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Inherit from `%<prefer>s` instead of `Exception`.'
        PREFERRED_BASE_CLASS = {
          runtime_error: 'RuntimeError',
          standard_error: 'StandardError'
        }.freeze

        RESTRICT_ON_SEND = %i[new].freeze

        # @!method class_new_call?(node)
        def_node_matcher :class_new_call?, <<~PATTERN
          (send
            (const {cbase nil?} :Class) :new
            $(const {cbase nil?} _))
        PATTERN

        def on_class(node)
          return unless node.parent_class && exception_class?(node.parent_class)
          return if inherit_exception_class_with_omitted_namespace?(node)

          message = message(node.parent_class)

          add_offense(node.parent_class, message: message) do |corrector|
            corrector.replace(node.parent_class, preferred_base_class)
          end
        end

        def on_send(node)
          constant = class_new_call?(node)
          return unless constant && exception_class?(constant)

          message = message(constant)

          add_offense(constant, message: message) do |corrector|
            corrector.replace(constant, preferred_base_class)
          end
        end

        private

        def message(node)
          format(MSG, prefer: preferred_base_class, current: node.const_name)
        end

        def exception_class?(class_node)
          class_node.const_name == 'Exception'
        end

        def inherit_exception_class_with_omitted_namespace?(class_node)
          return false if class_node.parent_class.namespace&.cbase_type?

          class_node.left_siblings.any? do |sibling|
            sibling.respond_to?(:identifier) && exception_class?(sibling.identifier)
          end
        end

        def preferred_base_class
          PREFERRED_BASE_CLASS[style]
        end
      end
    end
  end
end
