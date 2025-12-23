# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies usages of `count` on an `Enumerable` that
      # follow calls to `select`, `find_all`, `filter` or `reject`. Querying logic can instead be
      # passed to the `count` call.
      #
      # @safety
      #   This cop is unsafe because it has known compatibility issues with `ActiveRecord` and other
      #   frameworks. Before Rails 5.1, `ActiveRecord` will ignore the block that is passed to `count`.
      #   Other methods, such as `select`, will convert the association to an
      #   array and then run the block on the array. A simple work around to
      #   make `count` work with a block is to call `to_a.count {...}`.
      #
      #   For example:
      #
      #   [source,ruby]
      #   ----
      #   Model.where(id: [1, 2, 3]).select { |m| m.method == true }.size
      #   ----
      #
      #   becomes:
      #
      #   [source,ruby]
      #   ----
      #   Model.where(id: [1, 2, 3]).to_a.count { |m| m.method == true }
      #   ----
      #
      # @example
      #   # bad
      #   [1, 2, 3].select { |e| e > 2 }.size
      #   [1, 2, 3].reject { |e| e > 2 }.size
      #   [1, 2, 3].select { |e| e > 2 }.length
      #   [1, 2, 3].reject { |e| e > 2 }.length
      #   [1, 2, 3].select { |e| e > 2 }.count { |e| e.odd? }
      #   [1, 2, 3].reject { |e| e > 2 }.count { |e| e.even? }
      #   array.select(&:value).count
      #
      #   # good
      #   [1, 2, 3].count { |e| e > 2 }
      #   [1, 2, 3].count { |e| e < 2 }
      #   [1, 2, 3].count { |e| e > 2 && e.odd? }
      #   [1, 2, 3].count { |e| e < 2 && e.even? }
      #   Model.select('field AS field_one').count
      #   Model.select(:value).count
      class Count < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `count` instead of `%<selector>s...%<counter>s`.'
        RESTRICT_ON_SEND = %i[count length size].freeze

        def_node_matcher :count_candidate?, <<~PATTERN
          {
            (call (block $(call _ ${:select :filter :find_all :reject}) ...) ${:count :length :size})
            (call $(call _ ${:select :filter :find_all :reject} (:block_pass _)) ${:count :length :size})
          }
        PATTERN

        def on_send(node)
          count_candidate?(node) do |selector_node, selector, counter|
            return unless eligible_node?(node)

            range = source_starting_at(node) do
              selector_node.loc.selector.begin_pos
            end

            add_offense(range, message: format(MSG, selector: selector, counter: counter)) do |corrector|
              autocorrect(corrector, node, selector_node, selector)
            end
          end
        end
        alias on_csend on_send

        private

        def autocorrect(corrector, node, selector_node, selector)
          selector_loc = selector_node.loc.selector

          range = source_starting_at(node) { |n| n.loc.dot.begin_pos }

          corrector.remove(range)
          corrector.replace(selector_loc, 'count')
          negate_reject(corrector, node) if selector == :reject
        end

        def eligible_node?(node)
          !(node.parent && node.parent.block_type?)
        end

        def source_starting_at(node)
          begin_pos = if block_given?
                        yield node
                      else
                        node.source_range.begin_pos
                      end

          range_between(begin_pos, node.source_range.end_pos)
        end

        def negate_reject(corrector, node)
          if node.receiver.call_type?
            negate_block_pass_reject(corrector, node)
          else
            negate_block_reject(corrector, node)
          end
        end

        def negate_block_pass_reject(corrector, node)
          corrector.replace(
            node.receiver.source_range.with(begin_pos: node.receiver.loc.begin.begin_pos),
            negate_block_pass_as_inline_block(node.receiver)
          )
        end

        def negate_block_reject(corrector, node)
          target =
            if node.receiver.body.begin_type?
              node.receiver.body.children.last
            else
              node.receiver.body
            end
          corrector.replace(target, negate_expression(target))
        end

        def negate_expression(node)
          "!(#{node.source})"
        end

        def negate_block_pass_as_inline_block(node)
          if node.last_argument.children.first.sym_type?
            " { |element| !element.#{node.last_argument.children.first.value} }"
          else
            " { !#{node.last_argument.children.first.source}.call }"
          end
        end
      end
    end
  end
end
