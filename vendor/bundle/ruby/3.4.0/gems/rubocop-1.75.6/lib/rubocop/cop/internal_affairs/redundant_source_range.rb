# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for redundant `source_range`.
      #
      # @example
      #
      #   # bad
      #   node.source_range.source
      #
      #   # good
      #   node.source
      #
      #   # bad
      #   add_offense(node.source_range)
      #
      #   # good
      #   add_offense(node)
      #
      #   # bad
      #   add_offense(node) { |corrector| corrector.replace(node.source_range, prefer) }
      #   add_offense(node) { |corrector| corrector.insert_before(node.source_range, prefer) }
      #   add_offense(node) { |corrector| corrector.insert_before_multi(node.source_range, prefer) }
      #   add_offense(node) { |corrector| corrector.insert_after(node.source_range, prefer) }
      #   add_offense(node) { |corrector| corrector.insert_after_multi(node.source_range, prefer) }
      #   add_offense(node) { |corrector| corrector.swap(node.source_range, before, after) }
      #
      #   # good
      #   add_offense(node) { |corrector| corrector.replace(node, prefer) }
      #   add_offense(node) { |corrector| corrector.insert_before(node, prefer) }
      #   add_offense(node) { |corrector| corrector.insert_before_multi(node, prefer) }
      #   add_offense(node) { |corrector| corrector.insert_after(node, prefer) }
      #   add_offense(node) { |corrector| corrector.insert_after_multi(node, prefer) }
      #   add_offense(node) { |corrector| corrector.swap(node, before, after) }
      #
      class RedundantSourceRange < Base
        extend AutoCorrector

        MSG = 'Remove the redundant `source_range`.'
        RESTRICT_ON_SEND = %i[
          source add_offense
          replace remove insert_before insert_before_multi insert_after insert_after_multi swap
        ].freeze

        # @!method redundant_source_range(node)
        def_node_matcher :redundant_source_range, <<~PATTERN
          {
            (call $(call _ :source_range) :source)
            (send nil? :add_offense $(send _ :source_range) ...)
            (send _ {
              :replace :insert_before :insert_before_multi :insert_after :insert_after_multi
            } $(send _ :source_range) _)
            (send _ :remove $(send _ :source_range))
            (send _ :swap $(send _ :source_range) _ _)
          }
        PATTERN

        def on_send(node)
          return unless (source_range = redundant_source_range(node))
          return unless source_range.receiver
          return if source_range.receiver.send_type? && source_range.receiver.method?(:buffer)

          selector = source_range.loc.selector

          add_offense(selector) do |corrector|
            corrector.remove(source_range.loc.dot.join(selector))
          end
        end
        alias on_csend on_send
      end
    end
  end
end
