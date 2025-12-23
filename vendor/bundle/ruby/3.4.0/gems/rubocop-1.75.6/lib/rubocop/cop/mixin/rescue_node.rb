# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking `rescue` nodes.
    module RescueNode
      def modifier_locations
        @modifier_locations ||= processed_source.tokens.select(&:rescue_modifier?).map!(&:pos)
      end

      private

      def rescue_modifier?(node)
        return false unless node.respond_to?(:resbody_type?)

        node.resbody_type? && modifier_locations.include?(node.loc.keyword)
      end

      # @deprecated Use ResbodyNode#exceptions instead
      def rescued_exceptions(resbody)
        warn Rainbow(<<~WARNING).yellow, uplevel: 1
          `rescued_exceptions` is deprecated. Use `ResbodyNode#exceptions` instead.
        WARNING

        rescue_group, = *resbody
        if rescue_group
          rescue_group.values
        else
          []
        end
      end
    end
  end
end
