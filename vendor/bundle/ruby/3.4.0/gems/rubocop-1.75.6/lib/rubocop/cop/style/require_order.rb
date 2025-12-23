# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Sort `require` and `require_relative` in alphabetical order.
      #
      # @safety
      #   This cop's autocorrection is unsafe because it will obviously change the execution order.
      #
      # @example
      #   # bad
      #   require 'b'
      #   require 'a'
      #
      #   # good
      #   require 'a'
      #   require 'b'
      #
      #   # bad
      #   require_relative 'b'
      #   require_relative 'a'
      #
      #   # good
      #   require_relative 'a'
      #   require_relative 'b'
      #
      #   # good (sorted within each section separated by a blank line)
      #   require 'a'
      #   require 'd'
      #
      #   require 'b'
      #   require 'c'
      #
      #   # good
      #   require 'b'
      #   require_relative 'c'
      #   require 'a'
      #
      #   # bad
      #   require 'a'
      #   require 'c' if foo
      #   require 'b'
      #
      #   # good
      #   require 'a'
      #   require 'b'
      #   require 'c' if foo
      #
      #   # bad
      #   require 'c'
      #   if foo
      #     require 'd'
      #     require 'b'
      #   end
      #   require 'a'
      #
      #   # good
      #   require 'c'
      #   if foo
      #     require 'b'
      #     require 'd'
      #   end
      #   require 'a'
      #
      class RequireOrder < Base
        extend AutoCorrector

        include RangeHelp

        RESTRICT_ON_SEND = %i[require require_relative].freeze

        MSG = 'Sort `%<name>s` in alphabetical order.'

        # @!method if_inside_only_require(node)
        def_node_matcher :if_inside_only_require, <<~PATTERN
          {
            (if _ _ $(send nil? {:require :require_relative} _))
            (if _ $(send nil? {:require :require_relative} _) _)
          }
        PATTERN

        def on_send(node)
          return unless node.parent && node.arguments?
          return if not_modifier_form?(node.parent)

          previous_older_sibling = find_previous_older_sibling(node)
          return unless previous_older_sibling

          add_offense(node, message: format(MSG, name: node.method_name)) do |corrector|
            autocorrect(corrector, node, previous_older_sibling)
          end
        end

        private

        def not_modifier_form?(node)
          node.if_type? && !node.modifier_form?
        end

        def find_previous_older_sibling(node) # rubocop:disable Metrics
          search_node(node).left_siblings.reverse.find do |sibling|
            next unless sibling.is_a?(AST::Node)

            sibling = sibling_node(sibling)
            break unless sibling&.send_type? && sibling.method?(node.method_name)
            break unless sibling.arguments? && !sibling.receiver
            break unless in_same_section?(sibling, node)
            break unless node.first_argument.str_type? && sibling.first_argument.str_type?

            node.first_argument.value < sibling.first_argument.value
          end
        end

        def autocorrect(corrector, node, previous_older_sibling)
          range1 = range_with_comments_and_lines(previous_older_sibling)
          range2 = range_with_comments_and_lines(node.parent.if_type? ? node.parent : node)

          corrector.remove(range2)
          corrector.insert_before(range1, range2.source)
        end

        def search_node(node)
          node.parent.if_type? ? node.parent : node
        end

        def sibling_node(node)
          return if not_modifier_form?(node)

          node.if_type? ? if_inside_only_require(node) : node
        end

        def in_same_section?(node1, node2)
          !node1.source_range.join(node2.source_range.end).source.include?("\n\n")
        end
      end
    end
  end
end
