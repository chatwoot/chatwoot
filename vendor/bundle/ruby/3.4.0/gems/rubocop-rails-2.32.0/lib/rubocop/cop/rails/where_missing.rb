# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Use `where.missing(...)` to find missing relationship records.
      #
      # This cop is enabled in Rails 6.1 or higher.
      #
      # @example
      #   # bad
      #   Post.left_joins(:author).where(authors: { id: nil })
      #
      #   # good
      #   Post.where.missing(:author)
      #
      class WhereMissing < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Use `where.missing(:%<left_joins_association>s)` instead of ' \
              '`%<left_joins_method>s(:%<left_joins_association>s).where(%<where_association>s: { id: nil })`.'
        RESTRICT_ON_SEND = %i[left_joins left_outer_joins].freeze

        minimum_target_rails_version 6.1

        # @!method where_node_and_argument(node)
        def_node_search :where_node_and_argument, <<~PATTERN
          $(send ... :where (hash <(pair $(sym _) (hash (pair (sym :id) (nil))))...> ))
        PATTERN

        # @!method missing_relationship(node)
        def_node_search :missing_relationship, <<~PATTERN
          (pair (sym _) (hash (pair (sym :id) (nil))))
        PATTERN

        def on_send(node)
          return unless node.first_argument&.sym_type?

          root_receiver = root_receiver(node)
          where_node_and_argument(root_receiver) do |where_node, where_argument|
            next unless root_receiver == root_receiver(where_node)
            next unless same_relationship?(where_argument, node.first_argument)

            range = range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
            register_offense(node, where_node, where_argument, range)
            break
          end
        end

        private

        def root_receiver(node)
          parent = node.parent
          if !parent&.send_type? || parent.method?(:or) || parent.method?(:and)
            node
          else
            root_receiver(parent)
          end
        end

        def same_relationship?(where, left_joins)
          where.value.to_s.match?(/^#{left_joins.value}s?$/)
        end

        def register_offense(node, where_node, where_argument, range)
          add_offense(range, message: message(node, where_argument)) do |corrector|
            corrector.replace(node.loc.selector, 'where.missing')
            if multi_condition?(where_node.first_argument)
              replace_where_method(corrector, where_node)
            else
              remove_where_method(corrector, node, where_node)
            end
          end
        end

        def replace_where_method(corrector, where_node)
          missing_relationship(where_node) do |where_clause|
            corrector.remove(replace_range(where_clause))
          end
        end

        def replace_range(child)
          if (right_sibling = child.right_sibling)
            range_between(child.source_range.begin_pos, right_sibling.source_range.begin_pos)
          else
            range_between(child.left_sibling.source_range.end_pos, child.source_range.end_pos)
          end
        end

        # rubocop:disable Metrics/AbcSize
        def remove_where_method(corrector, node, where_node)
          range = range_between(where_node.loc.selector.begin_pos, where_node.loc.end.end_pos)
          if node.multiline? && !same_line?(node, where_node)
            range = range_by_whole_lines(range, include_final_newline: true)
          elsif where_node.receiver
            corrector.remove(where_node.loc.dot)
          else
            corrector.remove(node.loc.dot)
          end

          corrector.remove(range)
        end
        # rubocop:enable Metrics/AbcSize

        def same_line?(left_joins_node, where_node)
          left_joins_node.loc.selector.line == where_node.loc.selector.line
        end

        def multi_condition?(where_arg)
          where_arg.children.count > 1
        end

        def message(node, where_argument)
          format(MSG, left_joins_association: node.first_argument.value, left_joins_method: node.method_name,
                      where_association: where_argument.value)
        end
      end
    end
  end
end
