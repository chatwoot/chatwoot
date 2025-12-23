# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks to make sure safe navigation isn't used with `empty?` in
      # a conditional.
      #
      # While the safe navigation operator is generally a good idea, when
      # checking `foo&.empty?` in a conditional, `foo` being `nil` will actually
      # do the opposite of what the author intends.
      #
      # @example
      #   # bad
      #   return if foo&.empty?
      #   return unless foo&.empty?
      #
      #   # good
      #   return if foo && foo.empty?
      #   return unless foo && foo.empty?
      #
      class SafeNavigationWithEmpty < Base
        extend AutoCorrector

        MSG = 'Avoid calling `empty?` with the safe navigation operator in conditionals.'

        # @!method safe_navigation_empty_in_conditional?(node)
        def_node_matcher :safe_navigation_empty_in_conditional?, <<~PATTERN
          (if (csend (send ...) :empty?) ...)
        PATTERN

        def on_if(node)
          return unless safe_navigation_empty_in_conditional?(node)

          condition = node.condition

          add_offense(condition) do |corrector|
            receiver = condition.receiver.source

            corrector.replace(condition, "#{receiver} && #{receiver}.#{condition.method_name}")
          end
        end
      end
    end
  end
end
