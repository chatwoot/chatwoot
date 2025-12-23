# frozen_string_literal: true

module RuboCop
  module Cop
    module FactoryBot
      # Use definition in factory association instead of hard coding a strategy.
      #
      # @example
      #   # bad - only works for one strategy
      #   factory :foo do
      #     profile { create(:profile) }
      #   end
      #
      #   # good - implicit
      #   factory :foo do
      #     profile
      #   end
      #
      #   # good - explicit
      #   factory :foo do
      #     association :profile
      #   end
      #
      #   # good - inline
      #   factory :foo do
      #     profile { association :profile }
      #   end
      #
      class FactoryAssociationWithStrategy < ::RuboCop::Cop::Base
        MSG = 'Use an implicit, explicit or inline definition instead of ' \
              'hard coding a strategy for setting association within factory.'

        HARDCODED = Set.new(%i[create build build_stubbed]).freeze

        # @!method factory_declaration(node)
        def_node_matcher :factory_declaration, <<~PATTERN
          (block (send nil? {:factory :trait} ...)
            ...
          )
        PATTERN

        # @!method factory_strategy_association(node)
        def_node_matcher :factory_strategy_association, <<~PATTERN
          (block
            (send nil? _association_name)
            (args)
            < $(send nil? HARDCODED ...) ... >
          )
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          factory_declaration(node) do
            node.each_node do |statement|
              factory_strategy_association(statement) do |hardcoded_association|
                add_offense(hardcoded_association)
              end
            end
          end
        end
      end
    end
  end
end
