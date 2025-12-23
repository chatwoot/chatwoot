# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks the migration for which timestamps are not included when creating a new table.
      # In many cases, timestamps are useful information and should be added.
      #
      # NOTE: Allow `timestamps` not written when `id: false` because this emphasizes respecting
      # user's editing intentions.
      #
      # @example
      #   # bad
      #   create_table :users
      #
      #   # bad
      #   create_table :users do |t|
      #     t.string :name
      #     t.string :email
      #   end
      #
      #   # good
      #   create_table :users do |t|
      #     t.string :name
      #     t.string :email
      #
      #     t.timestamps
      #   end
      #
      #   # good
      #   create_table :users do |t|
      #     t.string :name
      #     t.string :email
      #
      #     t.datetime :created_at, default: -> { 'CURRENT_TIMESTAMP' }
      #   end
      #
      #   # good
      #   create_table :users do |t|
      #     t.string :name
      #     t.string :email
      #
      #     t.datetime :updated_at, default: -> { 'CURRENT_TIMESTAMP' }
      #   end
      #
      #   # good
      #   create_table :users, articles, id: false do |t|
      #     t.integer :user_id
      #     t.integer :article_id
      #   end
      #
      class CreateTableWithTimestamps < Base
        include ActiveRecordMigrationsHelper

        MSG = 'Add timestamps when creating a new table.'
        RESTRICT_ON_SEND = %i[create_table].freeze

        def_node_search :use_id_false_option?, <<~PATTERN
          (pair (sym :id) (false))
        PATTERN

        def_node_matcher :create_table_with_timestamps_proc?, <<~PATTERN
          (send nil? :create_table (sym _) ... (block-pass (sym :timestamps)))
        PATTERN

        def_node_search :timestamps_included?, <<~PATTERN
          (send _var :timestamps ...)
        PATTERN

        def_node_search :created_at_or_updated_at_included?, <<~PATTERN
          (send _var :datetime
            {(sym {:created_at :updated_at})(str {"created_at" "updated_at"})}
            ...)
        PATTERN

        def on_send(node)
          return if !node.command?(:create_table) || use_id_false_option?(node)

          parent = node.parent

          if create_table_with_block?(parent)
            add_offense(parent) if parent.body.nil? || !time_columns_included?(parent.body)
          elsif create_table_with_timestamps_proc?(node)
            # nothing to do
          else
            add_offense(node)
          end
        end

        private

        def time_columns_included?(node)
          timestamps_included?(node) || created_at_or_updated_at_included?(node)
        end
      end
    end
  end
end
