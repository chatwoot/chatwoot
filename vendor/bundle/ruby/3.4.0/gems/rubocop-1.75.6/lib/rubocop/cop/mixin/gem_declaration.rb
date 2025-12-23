# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking gem declarations.
    module GemDeclaration
      extend NodePattern::Macros

      # @!method gem_declaration?(node)
      def_node_matcher :gem_declaration?, '(send nil? :gem str ...)'
    end
  end
end
