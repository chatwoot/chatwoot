# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Helps check offenses with variable definitions
      module SkipOrPending
        extend RuboCop::NodePattern::Macros

        # @!method skipped_in_metadata?(node)
        def_node_matcher :skipped_in_metadata?, <<~PATTERN
          {
            (send _ _ <(sym {:skip :pending}) ...>)
            (send _ _ ... (hash <(pair (sym {:skip :pending}) { true str dstr }) ...>))
          }
        PATTERN

        # @!method skip_or_pending_inside_block?(node)
        #   Match skip/pending statements inside a block (e.g. `context`)
        #
        #   @example source that matches
        #     context 'when color is blue' do
        #       skip 'not implemented yet'
        #       pending 'not implemented yet'
        #     end
        #
        #   @example source that does not match
        #     skip 'not implemented yet'
        #     pending 'not implemented yet'
        #
        #   @param node [RuboCop::AST::Node]
        #   @return [Array<RuboCop::AST::Node>] matching nodes
        def_node_matcher :skip_or_pending_inside_block?, <<~PATTERN
          (block <(send nil? {:skip :pending} ...) ...>)
        PATTERN
      end
    end
  end
end
