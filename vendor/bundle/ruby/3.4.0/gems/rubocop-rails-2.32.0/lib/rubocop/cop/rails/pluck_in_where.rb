# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies places where `pluck` is used in `where` query methods
      # and can be replaced with `select`.
      #
      # Since `pluck` is an eager method and hits the database immediately,
      # using `select` helps to avoid additional database queries by running as
      # a subquery.
      #
      # This cop has two modes of enforcement. When the `EnforcedStyle` is set
      # to `conservative` (the default), only calls to `pluck` on a constant
      # (e.g. a model class) within `where` are considered offenses.
      #
      # @safety
      #   When `EnforcedStyle` is set to `aggressive`, all calls to `pluck`
      #   within `where` are considered offenses. This might lead to false
      #   positives because the check cannot distinguish between calls to
      #   `pluck` on an `ActiveRecord::Relation` instance and calls to `pluck`
      #   on an `Array` instance.
      #
      #   Additionally, when using a subquery with the SQL `IN` operator,
      #   databases like PostgreSQL and MySQL can't optimize complex queries as
      #   well. They need to scan all records of the outer table against the
      #   subquery result sequentially, rather than using an index. This can
      #   cause significant performance issues compared to writing the query
      #   differently or using `pluck`.
      #
      # @example
      #   # bad
      #   Post.where(user_id: User.active.pluck(:id))
      #   Post.where(user_id: User.active.ids)
      #   Post.where.not(user_id: User.active.pluck(:id))
      #
      #   # good
      #   Post.where(user_id: User.active.select(:id))
      #   Post.where(user_id: active_users.select(:id))
      #   Post.where.not(user_id: active_users.select(:id))
      #
      # @example EnforcedStyle: conservative (default)
      #   # good
      #   Post.where(user_id: active_users.pluck(:id))
      #
      # @example EnforcedStyle: aggressive
      #   # bad
      #   Post.where(user_id: active_users.pluck(:id))
      #
      class PluckInWhere < Base
        include ActiveRecordHelper
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG_SELECT = 'Use `select` instead of `pluck` within `where` query method.'
        MSG_IDS = 'Use `select(:id)` instead of `ids` within `where` query method.'
        RESTRICT_ON_SEND = %i[pluck ids].freeze

        def on_send(node)
          return unless in_where?(node)
          return if style == :conservative && !root_receiver(node)&.const_type?

          range = node.loc.selector

          if node.method?(:ids)
            replacement = 'select(:id)'
            message = MSG_IDS
          else
            replacement = 'select'
            message = MSG_SELECT
          end

          add_offense(range, message: message) do |corrector|
            corrector.replace(range, replacement)
          end
        end
        alias on_csend on_send

        private

        def root_receiver(node)
          receiver = node.receiver

          if receiver&.call_type?
            root_receiver(receiver)
          else
            receiver
          end
        end
      end
    end
  end
end
