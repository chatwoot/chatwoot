# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies calls to `where.not` with multiple hash arguments.
      #
      # The behavior of `where.not` changed in Rails 6.1. Prior to the change,
      # `.where.not(trashed: true, role: 'admin')` evaluated to
      # `WHERE trashed != TRUE AND role != 'admin'`.
      # From Rails 6.1 onwards, this executes the query
      # `WHERE NOT (trashed == TRUE AND roles == 'admin')`.
      #
      # @example
      #   # bad
      #   User.where.not(trashed: true, role: 'admin')
      #   User.where.not(trashed: true, role: ['moderator', 'admin'])
      #   User.joins(:posts).where.not(posts: { trashed: true, title: 'Rails' })
      #
      #   # good
      #   User.where.not(trashed: true)
      #   User.where.not(role: ['moderator', 'admin'])
      #   User.where.not(trashed: true).where.not(role: ['moderator', 'admin'])
      #   User.where.not('trashed = ? OR role = ?', true, 'admin')
      class WhereNotWithMultipleConditions < Base
        MSG = 'Use a SQL statement instead of `where.not` with multiple conditions.'
        RESTRICT_ON_SEND = %i[not].freeze

        def_node_matcher :where_not_call?, <<~PATTERN
          (send (send _ :where) :not $...)
        PATTERN

        def on_send(node)
          where_not_call?(node) do |args|
            next unless args[0]&.hash_type?
            next unless multiple_arguments_hash? args[0]

            range = node.receiver.loc.selector.with(end_pos: node.source_range.end_pos)

            add_offense(range)
          end
        end

        private

        def multiple_arguments_hash?(hash)
          return true if hash.pairs.size >= 2
          return false unless hash.values[0]&.hash_type?

          multiple_arguments_hash?(hash.values[0])
        end
      end
    end
  end
end
