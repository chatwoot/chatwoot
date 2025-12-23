# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces that boolean columns are created with default values (`false` or `true`) and
      # `NOT NULL` constraint.
      #
      # @example
      #   # bad
      #   add_column :users, :active, :boolean
      #   t.column :active, :boolean
      #   t.boolean :active
      #
      #   # good
      #   add_column :users, :active, :boolean, default: true, null: false
      #   t.column :active, :boolean, default: true, null: false
      #   t.boolean :active, default: true, null: false
      #
      class ThreeStateBooleanColumn < Base
        include MigrationsHelper

        MSG = 'Boolean columns should always have a default value and a `NOT NULL` constraint.'
        RESTRICT_ON_SEND = %i[add_column column boolean].freeze

        def_node_matcher :three_state_boolean?, <<~PATTERN
          {
            (send nil? :add_column _ $_ {(sym :boolean) (str "boolean")} $_ ?)
            (send !nil? :column $_ {(sym :boolean) (str "boolean")} $_ ?)
            (send !nil? :boolean $_ $_ ?)
          }
        PATTERN

        def_node_matcher :required_options?, <<~PATTERN
          (hash <(pair (sym :default) !nil?) (pair (sym :null) false) ...>)
        PATTERN

        def_node_search :change_column_null?, <<~PATTERN
          (send nil? :change_column_null %1 %2 false)
        PATTERN

        def on_send(node)
          three_state_boolean?(node) do |column_node, options_node|
            options_node = options_node.first

            return if required_options?(options_node)

            def_node = node.each_ancestor(:any_def).first
            table_node = table_node(node)
            return if def_node && (table_node.nil? || change_column_null?(def_node, table_node, column_node))

            add_offense(node)
          end
        end

        private

        def table_node(node)
          case node.method_name
          when :add_column
            node.first_argument
          when :column, :boolean
            ancestor = node.each_ancestor(:block).find do |n|
              n.method?(:create_table) || n.method?(:change_table)
            end
            ancestor&.send_node&.first_argument
          end
        end
      end
    end
  end
end
