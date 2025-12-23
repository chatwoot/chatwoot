# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for use of the helper methods which reference
      # instance variables.
      #
      # Relying on instance variables makes it difficult to reuse helper
      # methods.
      #
      # If it seems awkward to explicitly pass in each dependent
      # variable, consider moving the behavior elsewhere, for
      # example to a model, decorator or presenter.
      #
      # Provided that a class inherits `ActionView::Helpers::FormBuilder`,
      # an offense will not be registered.
      #
      # @example
      #   # bad
      #   def welcome_message
      #     "Hello #{@user.name}"
      #   end
      #
      #   # good
      #   def welcome_message(user)
      #     "Hello #{user.name}"
      #   end
      #
      #   # good
      #   class MyFormBuilder < ActionView::Helpers::FormBuilder
      #     @template.do_something
      #   end
      class HelperInstanceVariable < Base
        MSG = 'Do not use instance variables in helpers.'

        def_node_matcher :form_builder_class?, <<~PATTERN
          (const
            (const
               (const {nil? cbase} :ActionView) :Helpers) :FormBuilder)
        PATTERN

        def on_ivar(node)
          return if inherit_form_builder?(node)

          add_offense(node)
        end

        def on_ivasgn(node)
          return if node.parent.or_asgn_type? || inherit_form_builder?(node)

          add_offense(node.loc.name)
        end

        private

        def inherit_form_builder?(node)
          node.each_ancestor(:class) do |class_node|
            return true if form_builder_class?(class_node.parent_class)
          end

          false
        end
      end
    end
  end
end
