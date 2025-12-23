# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking gem declarations.
    module GemspecHelp
      extend NodePattern::Macros

      # @!method gem_specification?(node)
      def_node_matcher :gem_specification?, <<~PATTERN
        (block
          (send
            (const
              (const {cbase nil?} :Gem) :Specification) :new)
          (args
            (arg $_)) ...)
      PATTERN

      # @!method gem_specification(node)
      def_node_search :gem_specification, <<~PATTERN
        (block
          (send
            (const
              (const {cbase nil?} :Gem) :Specification) :new)
          (args
            (arg $_)) ...)
      PATTERN
    end
  end
end
