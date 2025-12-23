# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for cops working with routes.
    module RoutesHelper
      extend NodePattern::Macros

      HTTP_METHODS = %i[get post put patch delete].freeze

      def_node_matcher :routes_draw?, <<~PATTERN
        (send (send _ :routes) :draw)
      PATTERN

      def within_routes?(node)
        node.each_ancestor(:block).any? { |block| routes_draw?(block.send_node) }
      end
    end
  end
end
