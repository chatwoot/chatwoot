# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces the use of `ids` over `pluck(:id)` and `pluck(primary_key)`.
      #
      # @safety
      #   This cop is unsafe if the receiver object is not an Active Record object.
      #
      # @example
      #   # bad
      #   User.pluck(:id)
      #   user.posts.pluck(:id)
      #
      #   def self.user_ids
      #     pluck(primary_key)
      #   end
      #
      #   # good
      #   User.ids
      #   user.posts.ids
      #
      #   def self.user_ids
      #     ids
      #   end
      #
      class PluckId < Base
        include RangeHelp
        include ActiveRecordHelper
        extend AutoCorrector

        MSG = 'Use `ids` instead of `%<bad_method>s`.'
        RESTRICT_ON_SEND = %i[pluck].freeze

        def_node_matcher :pluck_id_call?, <<~PATTERN
          (call _ :pluck {(sym :id) (send nil? :primary_key)})
        PATTERN

        def on_send(node)
          return if !pluck_id_call?(node) || in_where?(node)

          range = offense_range(node)
          message = format(MSG, bad_method: range.source)

          add_offense(range, message: message) do |corrector|
            corrector.replace(offense_range(node), 'ids')
          end
        end
        alias on_csend on_send

        private

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end
      end
    end
  end
end
