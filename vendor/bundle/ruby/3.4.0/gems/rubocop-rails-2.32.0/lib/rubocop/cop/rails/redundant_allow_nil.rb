# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks Rails model validations for a redundant `allow_nil` when
      # `allow_blank` is present.
      #
      # @example
      #   # bad
      #   validates :x, length: { is: 5 }, allow_nil: true, allow_blank: true
      #
      #   # bad
      #   validates :x, length: { is: 5 }, allow_nil: false, allow_blank: true
      #
      #   # bad
      #   validates :x, length: { is: 5 }, allow_nil: false, allow_blank: false
      #
      #   # good
      #   validates :x, length: { is: 5 }, allow_blank: true
      #
      #   # good
      #   validates :x, length: { is: 5 }, allow_blank: false
      #
      #   # good
      #   # Here, `nil` is valid but `''` is not
      #   validates :x, length: { is: 5 }, allow_nil: true, allow_blank: false
      #
      class RedundantAllowNil < Base
        include RangeHelp
        extend AutoCorrector

        MSG_SAME = '`allow_nil` is redundant when `allow_blank` has the same value.'

        MSG_ALLOW_NIL_FALSE = '`allow_nil: false` is redundant when `allow_blank` is true.'

        RESTRICT_ON_SEND = %i[validates].freeze

        def on_send(node)
          allow_nil, allow_blank = find_allow_nil_and_allow_blank(node)
          return unless allow_nil && allow_blank

          allow_nil_val = allow_nil.children.last
          allow_blank_val = allow_blank.children.last

          if allow_nil_val.type == allow_blank_val.type
            register_offense(allow_nil, MSG_SAME)
          elsif allow_nil_val.false_type? && allow_blank_val.true_type?
            register_offense(allow_nil, MSG_ALLOW_NIL_FALSE)
          end
        end

        private

        def register_offense(allow_nil, message)
          add_offense(allow_nil, message: message) do |corrector|
            prv_sib = allow_nil.left_sibling
            nxt_sib = allow_nil.right_sibling

            if nxt_sib
              corrector.remove(range_between(node_beg(allow_nil), node_beg(nxt_sib)))
            elsif prv_sib
              corrector.remove(range_between(node_end(prv_sib), node_end(allow_nil)))
            else
              corrector.remove(allow_nil)
            end
          end
        end

        def find_allow_nil_and_allow_blank(node)
          allow_nil, allow_blank = nil

          node.each_child_node do |child_node|
            if child_node.pair_type?
              key = child_node.children.first.source

              allow_nil = child_node if key == 'allow_nil'
              allow_blank = child_node if key == 'allow_blank'
            end
            return [allow_nil, allow_blank] if allow_nil && allow_blank

            found_in_children_nodes = find_allow_nil_and_allow_blank(child_node)
            return found_in_children_nodes if found_in_children_nodes
          end

          nil
        end

        def node_beg(node)
          node.source_range.begin_pos
        end

        def node_end(node)
          node.source_range.end_pos
        end
      end
    end
  end
end
