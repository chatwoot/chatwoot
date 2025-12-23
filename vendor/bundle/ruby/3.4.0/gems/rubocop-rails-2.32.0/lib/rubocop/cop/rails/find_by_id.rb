# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces that `ActiveRecord#find` is used instead of
      # `where.take!`, `find_by!`, and `find_by_id!` to retrieve a single record
      # by primary key when you expect it to be found.
      #
      # @example
      #   # bad
      #   User.where(id: id).take!
      #   User.find_by_id!(id)
      #   User.find_by!(id: id)
      #
      #   # good
      #   User.find(id)
      #
      class FindById < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<good_method>s` instead of `%<bad_method>s`.'
        RESTRICT_ON_SEND = %i[take! find_by_id! find_by!].freeze

        def_node_matcher :where_take?, <<~PATTERN
          (call
            $(call _ :where
              (hash
                (pair (sym :id) $_))) :take!)
        PATTERN

        def_node_matcher :find_by?, <<~PATTERN
          {
            (call _ :find_by_id! $_)
            (call _ :find_by! (hash (pair (sym :id) $_)))
          }
        PATTERN

        def on_send(node)
          where_take?(node) do |where, id_value|
            range = where_take_offense_range(node, where)

            register_offense(range, id_value)
          end

          find_by?(node) do |id_value|
            range = find_by_offense_range(node)

            register_offense(range, id_value)
          end
        end
        alias on_csend on_send

        private

        def register_offense(range, id_value)
          good_method = build_good_method(id_value)
          message = format(MSG, good_method: good_method, bad_method: range.source)

          add_offense(range, message: message) do |corrector|
            corrector.replace(range, good_method)
          end
        end

        def where_take_offense_range(node, where)
          range_between(where.loc.selector.begin_pos, node.source_range.end_pos)
        end

        def find_by_offense_range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end

        def build_good_method(id_value)
          "find(#{id_value.source})"
        end
      end
    end
  end
end
