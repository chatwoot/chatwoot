# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Detect redundant `all` used as a receiver for Active Record query methods.
      #
      # For the methods `delete_all` and `destroy_all`, this cop will only check cases where the receiver is a model.
      # It will ignore cases where the receiver is an association (e.g., `user.articles.all.delete_all`).
      # This is because omitting `all` from an association changes the methods
      # from `ActiveRecord::Relation` to `ActiveRecord::Associations::CollectionProxy`,
      # which can affect their behavior.
      #
      # @safety
      #   This cop is unsafe for autocorrection if the receiver for `all` is not an Active Record object.
      #
      # @example
      #   # bad
      #   User.all.find(id)
      #   User.all.order(:created_at)
      #   users.all.where(id: ids)
      #   user.articles.all.order(:created_at)
      #
      #   # good
      #   User.find(id)
      #   User.order(:created_at)
      #   users.where(id: ids)
      #   user.articles.order(:created_at)
      #
      # @example AllowedReceivers: ['ActionMailer::Preview', 'ActiveSupport::TimeZone'] (default)
      #   # good
      #   ActionMailer::Preview.all.first
      #   ActiveSupport::TimeZone.all.first
      class RedundantActiveRecordAllMethod < Base
        include ActiveRecordHelper
        include AllowedReceivers
        include RangeHelp
        extend AutoCorrector

        MSG = 'Redundant `all` detected.'

        RESTRICT_ON_SEND = [:all].freeze

        # Defined methods in `ActiveRecord::Querying::QUERYING_METHODS` on activerecord 7.1.0.
        QUERYING_METHODS = %i[
          and
          annotate
          any?
          async_average
          async_count
          async_ids
          async_maximum
          async_minimum
          async_pick
          async_pluck
          async_sum
          average
          calculate
          count
          create_or_find_by
          create_or_find_by!
          create_with
          delete_all
          delete_by
          destroy_all
          destroy_by
          distinct
          eager_load
          except
          excluding
          exists?
          extending
          extract_associated
          fifth
          fifth!
          find
          find_by
          find_by!
          find_each
          find_in_batches
          find_or_create_by
          find_or_create_by!
          find_or_initialize_by
          find_sole_by
          first
          first!
          first_or_create
          first_or_create!
          first_or_initialize
          forty_two
          forty_two!
          fourth
          fourth!
          from
          group
          having
          ids
          in_batches
          in_order_of
          includes
          invert_where
          joins
          last
          last!
          left_joins
          left_outer_joins
          limit
          lock
          many?
          maximum
          merge
          minimum
          none
          none?
          offset
          one?
          only
          optimizer_hints
          or
          order
          pick
          pluck
          preload
          readonly
          references
          regroup
          reorder
          reselect
          rewhere
          second
          second!
          second_to_last
          second_to_last!
          select
          sole
          strict_loading
          sum
          take
          take!
          third
          third!
          third_to_last
          third_to_last!
          touch_all
          unscope
          update_all
          where
          with
          without
        ].to_set.freeze

        POSSIBLE_ENUMERABLE_BLOCK_METHODS = %i[any? count find none? one? select sum].freeze
        SENSITIVE_METHODS_ON_ASSOCIATION = %i[delete_all destroy_all].freeze

        def_node_matcher :followed_by_query_method?, <<~PATTERN
          (send (send _ :all) QUERYING_METHODS ...)
        PATTERN

        def on_send(node)
          return unless followed_by_query_method?(node.parent)
          return if possible_enumerable_block_method?(node) || sensitive_association_method?(node)
          return if node.receiver ? allowed_receiver?(node.receiver) : !inherit_active_record_base?(node)

          range_of_all_method = offense_range(node)
          add_offense(range_of_all_method) do |collector|
            collector.remove(range_of_all_method)
            collector.remove(node.parent.loc.dot)
          end
        end

        private

        def possible_enumerable_block_method?(node)
          parent = node.parent
          return false unless POSSIBLE_ENUMERABLE_BLOCK_METHODS.include?(parent.method_name)

          parent.block_literal? || parent.first_argument&.block_pass_type?
        end

        def sensitive_association_method?(node)
          !node.receiver&.const_type? && SENSITIVE_METHODS_ON_ASSOCIATION.include?(node.parent.method_name)
        end

        def offense_range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end
      end
    end
  end
end
