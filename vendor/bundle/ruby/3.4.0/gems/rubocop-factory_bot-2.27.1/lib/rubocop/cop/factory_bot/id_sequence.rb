# frozen_string_literal: true

module RuboCop
  module Cop
    module FactoryBot
      # Do not create a FactoryBot sequence for an id column.
      #
      # @example
      #   # bad - can lead to conflicts between FactoryBot and DB sequences
      #   factory :foo do
      #     sequence :id
      #   end
      #
      #   # good - a non-id column
      #   factory :foo do
      #     sequence :some_non_id_column
      #   end
      #
      class IdSequence < ::RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp
        include RuboCop::FactoryBot::Language

        MSG = 'Do not create a sequence for an id attribute'
        RESTRICT_ON_SEND = %i[sequence].freeze

        def on_send(node)
          return unless node.receiver.nil? || factory_bot?(node.receiver)
          return unless node.first_argument&.sym_type? &&
            node.first_argument.value == :id

          add_offense(node) do |corrector|
            range_to_remove = range_by_whole_lines(
              node.source_range,
              include_final_newline: true
            )

            corrector.remove(range_to_remove)
          end
        end
      end
    end
  end
end
