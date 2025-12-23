# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Identifies instances of sorting and then
      # taking only the first or last element. The same behavior can
      # be accomplished without a relatively expensive sort by using
      # `Enumerable#min` instead of sorting and taking the first
      # element and `Enumerable#max` instead of sorting and taking the
      # last element. Similarly, `Enumerable#min_by` and
      # `Enumerable#max_by` can replace `Enumerable#sort_by` calls
      # after which only the first or last element is used.
      #
      # @safety
      #   This cop is unsafe, because `sort...last` and `max` may not return the
      #   same element in all cases.
      #
      #   In an enumerable where there are multiple elements where ``a <=> b == 0``,
      #   or where the transformation done by the `sort_by` block has the
      #   same result, `sort.last` and `max` (or `sort_by.last` and `max_by`)
      #   will return different elements. `sort.last` will return the last
      #   element but `max` will return the first element.
      #
      #   For example:
      #
      #   [source,ruby]
      #   ----
      #     class MyString < String; end
      #     strings = [MyString.new('test'), 'test']
      #     strings.sort.last.class   #=> String
      #     strings.max.class         #=> MyString
      #   ----
      #
      #   [source,ruby]
      #   ----
      #     words = %w(dog horse mouse)
      #     words.sort_by { |word| word.length }.last   #=> 'mouse'
      #     words.max_by { |word| word.length }         #=> 'horse'
      #   ----
      #
      # @example
      #   # bad
      #   [2, 1, 3].sort.first
      #   [2, 1, 3].sort[0]
      #   [2, 1, 3].sort.at(0)
      #   [2, 1, 3].sort.slice(0)
      #
      #   # good
      #   [2, 1, 3].min
      #
      #   # bad
      #   [2, 1, 3].sort.last
      #   [2, 1, 3].sort[-1]
      #   [2, 1, 3].sort.at(-1)
      #   [2, 1, 3].sort.slice(-1)
      #
      #   # good
      #   [2, 1, 3].max
      #
      #   # bad
      #   arr.sort_by(&:foo).first
      #   arr.sort_by(&:foo)[0]
      #   arr.sort_by(&:foo).at(0)
      #   arr.sort_by(&:foo).slice(0)
      #
      #   # good
      #   arr.min_by(&:foo)
      #
      #   # bad
      #   arr.sort_by(&:foo).last
      #   arr.sort_by(&:foo)[-1]
      #   arr.sort_by(&:foo).at(-1)
      #   arr.sort_by(&:foo).slice(-1)
      #
      #   # good
      #   arr.max_by(&:foo)
      #
      class RedundantSort < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<suggestion>s` instead of `%<sorter>s...%<accessor_source>s`.'

        RESTRICT_ON_SEND = %i[sort sort_by].freeze

        # @!method redundant_sort?(node)
        def_node_matcher :redundant_sort?, <<~MATCHER
          {
            (call $(call _ $:sort) ${:last :first})
            (call $(call _ $:sort) ${:[] :at :slice} {(int 0) (int -1)})

            (call $(call _ $:sort_by _) ${:last :first})
            (send $(send _ $:sort_by _) ${:[] :at :slice} {(int 0) (int -1)})

            (call (any_block $(call _ ${:sort_by :sort}) ...) ${:last :first})
            (call
              (any_block $(call _ ${:sort_by :sort}) ...)
              ${:[] :at :slice} {(int 0) (int -1)}
            )
          }
        MATCHER

        def on_send(node)
          ancestor, sort_node, sorter, accessor =
            find_redundant_sort(node.parent, node.parent&.parent)
          return unless ancestor

          register_offense(ancestor, sort_node, sorter, accessor)
        end
        alias on_csend on_send

        private

        def find_redundant_sort(*nodes)
          nodes.each do |node|
            if (sort_node, sorter, accessor = redundant_sort?(node))
              return [node, sort_node, sorter, accessor]
            end
          end

          nil
        end

        def register_offense(node, sort_node, sorter, accessor)
          message = message(node, sorter, accessor)
          add_offense(offense_range(sort_node, node), message: message) do |corrector|
            autocorrect(corrector, node, sort_node, sorter, accessor)
          end
        end

        def offense_range(sort_node, node)
          range_between(sort_node.loc.selector.begin_pos, node.source_range.end_pos)
        end

        def message(node, sorter, accessor)
          accessor_source = range_between(
            node.loc.selector.begin_pos,
            node.source_range.end_pos
          ).source

          format(MSG,
                 suggestion: suggestion(sorter, accessor, arg_value(node)),
                 sorter: sorter,
                 accessor_source: accessor_source)
        end

        def autocorrect(corrector, node, sort_node, sorter, accessor)
          # Remove accessor, e.g. `first` or `[-1]`.
          corrector.remove(range_between(accessor_start(node), node.source_range.end_pos))
          # Replace "sort" or "sort_by" with the appropriate min/max method.
          corrector.replace(sort_node.loc.selector, suggestion(sorter, accessor, arg_value(node)))
          # Replace to avoid syntax errors when followed by a logical operator.
          replace_with_logical_operator(corrector, node) if with_logical_operator?(node)
        end

        def replace_with_logical_operator(corrector, node)
          corrector.insert_after(node.child_nodes.first, " #{node.parent.loc.operator.source}")
          corrector.remove(node.parent.loc.operator)
        end

        def suggestion(sorter, accessor, arg)
          base(accessor, arg) + suffix(sorter)
        end

        def base(accessor, arg)
          if accessor == :first || arg&.zero?
            'min'
          elsif accessor == :last || arg == -1
            'max'
          end
        end

        def suffix(sorter)
          case sorter
          when :sort
            ''
          when :sort_by
            '_by'
          end
        end

        def arg_node(node)
          node.first_argument
        end

        def arg_value(node)
          arg_node(node)&.node_parts&.first
        end

        # This gets the start of the accessor whether it has a dot
        # (e.g. `.first`) or doesn't (e.g. `[0]`)
        def accessor_start(node)
          if node.loc.dot
            node.loc.dot.begin_pos
          else
            node.loc.selector.begin_pos
          end
        end

        def with_logical_operator?(node)
          return false unless (parent = node.parent)

          parent.operator_keyword?
        end
      end
    end
  end
end
