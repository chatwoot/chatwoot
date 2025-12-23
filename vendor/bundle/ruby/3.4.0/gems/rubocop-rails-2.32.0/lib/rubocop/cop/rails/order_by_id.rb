# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for places where ordering by `id` column is used.
      #
      # Don't use the `id` column for ordering. The sequence of ids is not guaranteed
      # to be in any particular order, despite often (incidentally) being chronological.
      # Use a timestamp column to order chronologically. As a bonus the intent is clearer.
      #
      # NOTE: Make sure the changed order column does not introduce performance
      # bottlenecks and appropriate database indexes are added.
      #
      # @example
      #   # bad
      #   scope :chronological, -> { order(id: :asc) }
      #   scope :chronological, -> { order(primary_key => :asc) }
      #
      #   # good
      #   scope :chronological, -> { order(created_at: :asc) }
      #
      class OrderById < Base
        include RangeHelp

        MSG = 'Do not use the `id` column for ordering. Use a timestamp column to order chronologically.'
        RESTRICT_ON_SEND = %i[order].freeze

        def_node_matcher :order_by_id?, <<~PATTERN
          (send _ :order
            {
              (sym :id)
              (hash (pair (sym :id) _))
              (send _ :primary_key)
              (hash (pair (send _ :primary_key) _))
            })
        PATTERN

        def on_send(node)
          add_offense(offense_range(node)) if order_by_id?(node)
        end

        private

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end
      end
    end
  end
end
