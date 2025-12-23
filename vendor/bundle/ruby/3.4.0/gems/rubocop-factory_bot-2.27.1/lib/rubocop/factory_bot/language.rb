# frozen_string_literal: true

module RuboCop
  module FactoryBot
    # Contains node matchers for common factory_bot DSL.
    module Language
      extend RuboCop::NodePattern::Macros

      METHODS = %i[
        attributes_for
        attributes_for_list
        attributes_for_pair
        build
        build_list
        build_pair
        build_stubbed
        build_stubbed_list
        build_stubbed_pair
        create
        create_list
        create_pair
        generate
        generate_list
        null
        null_list
        null_pair
      ].to_set.freeze

      # @!method factory_bot?(node)
      def_node_matcher :factory_bot?, <<~PATTERN
        (const {nil? cbase} {:FactoryGirl :FactoryBot})
      PATTERN
    end
  end
end
