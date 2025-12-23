# frozen_string_literal: true

module RuboCop
  module Cop
    # Help methods for working with `Enumerable#dig` in cops.
    # Used by `Style::DigChain` and `Style::SingleArgumentDig`
    module DigHelp
      extend NodePattern::Macros

      # @!method dig?(node)
      def_node_matcher :dig?, <<~PATTERN
        (call _ :dig !{hash block_pass}+)
      PATTERN

      # @!method single_argument_dig?(node)
      def_node_matcher :single_argument_dig?, <<~PATTERN
        (send _ :dig $!splat)
      PATTERN

      private

      def dig_chain_enabled?
        @config.cop_enabled?('Style/DigChain')
      end
    end
  end
end
