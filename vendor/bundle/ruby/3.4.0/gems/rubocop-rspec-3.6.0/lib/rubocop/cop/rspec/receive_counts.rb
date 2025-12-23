# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for `once` and `twice` receive counts matchers usage.
      #
      # @example
      #   # bad
      #   expect(foo).to receive(:bar).exactly(1).times
      #   expect(foo).to receive(:bar).exactly(2).times
      #   expect(foo).to receive(:bar).at_least(1).times
      #   expect(foo).to receive(:bar).at_least(2).times
      #   expect(foo).to receive(:bar).at_most(1).times
      #   expect(foo).to receive(:bar).at_most(2).times
      #
      #   # good
      #   expect(foo).to receive(:bar).once
      #   expect(foo).to receive(:bar).twice
      #   expect(foo).to receive(:bar).at_least(:once)
      #   expect(foo).to receive(:bar).at_least(:twice)
      #   expect(foo).to receive(:bar).at_most(:once)
      #   expect(foo).to receive(:bar).at_most(:twice).times
      #
      class ReceiveCounts < Base
        extend AutoCorrector

        MSG = 'Use `%<alternative>s` instead of `%<original>s`.'

        RESTRICT_ON_SEND = %i[times].freeze

        # @!method receive_counts(node)
        def_node_matcher :receive_counts, <<~PATTERN
          (send $(send _ {:exactly :at_least :at_most} (int {1 2})) :times)
        PATTERN

        # @!method stub?(node)
        def_node_search :stub?, '(send nil? :receive ...)'

        def on_send(node)
          receive_counts(node) do |offending_node|
            return unless stub?(offending_node.receiver)

            offending_range = range(node, offending_node)

            msg = message_for(offending_node, offending_range.source)
            add_offense(offending_range, message: msg) do |corrector|
              autocorrect(corrector, offending_node, offending_range)
            end
          end
        end

        private

        def autocorrect(corrector, node, range)
          replacement = matcher_for(
            node.method_name,
            node.first_argument.source.to_i
          )

          corrector.replace(range, replacement)
        end

        def message_for(node, source)
          alternative = matcher_for(
            node.method_name,
            node.first_argument.source.to_i
          )
          format(MSG, alternative: alternative, original: source)
        end

        def matcher_for(method, count)
          matcher = count == 1 ? 'once' : 'twice'
          if method == :exactly
            ".#{matcher}"
          else
            ".#{method}(:#{matcher})"
          end
        end

        def range(node, offending_node)
          offending_node.loc.dot.with(
            end_pos: node.source_range.end_pos
          )
        end
      end
    end
  end
end
