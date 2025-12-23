# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies top-level `HashWithIndifferentAccess`.
      # This has been soft-deprecated since Rails 5.1.
      #
      # @example
      #   # bad
      #   HashWithIndifferentAccess.new(foo: 'bar')
      #
      #   # good
      #   ActiveSupport::HashWithIndifferentAccess.new(foo: 'bar')
      #
      class TopLevelHashWithIndifferentAccess < Base
        extend AutoCorrector
        extend TargetRailsVersion

        minimum_target_rails_version 5.1

        MSG = 'Avoid top-level `HashWithIndifferentAccess`.'

        # @!method top_level_hash_with_indifferent_access?(node)
        #   @param [RuboCop::AST::ConstNode] node
        #   @return [Boolean]
        def_node_matcher :top_level_hash_with_indifferent_access?, <<~PATTERN
          (const {nil? cbase} :HashWithIndifferentAccess)
        PATTERN

        # @param [RuboCop::AST::ConstNode] node
        def on_const(node)
          return unless top_level_hash_with_indifferent_access?(node)
          return if node.parent&.class_type? && node.parent.ancestors.any?(&:module_type?)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def autocorrect(corrector, node)
          corrector.insert_before(node.location.name, 'ActiveSupport::')
        end
      end
    end
  end
end
