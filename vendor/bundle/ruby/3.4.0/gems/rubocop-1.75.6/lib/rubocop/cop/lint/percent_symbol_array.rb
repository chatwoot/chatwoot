# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for colons and commas in %i, e.g. `%i(:foo, :bar)`
      #
      # It is more likely that the additional characters are unintended (for
      # example, mistranslating an array of literals to percent string notation)
      # rather than meant to be part of the resulting symbols.
      #
      # @example
      #
      #   # bad
      #   %i(:foo, :bar)
      #
      #   # good
      #   %i(foo bar)
      class PercentSymbolArray < Base
        include PercentLiteral
        extend AutoCorrector

        MSG = "Within `%i`/`%I`, ':' and ',' are unnecessary and may be " \
              'unwanted in the resulting symbols.'

        def on_array(node)
          process(node, '%i', '%I')
        end

        def on_percent_literal(node)
          return unless contains_colons_or_commas?(node)

          add_offense(node) { |corrector| autocorrect(corrector, node) }
        end

        private

        def autocorrect(corrector, node)
          node.children.each do |child|
            range = child.source_range

            corrector.remove_trailing(range, 1) if range.source.end_with?(',')
            corrector.remove_leading(range, 1) if
              range.source.start_with?(':')
          end
        end

        def contains_colons_or_commas?(node)
          node.children.any? do |child|
            literal = child.children.first.to_s

            next if non_alphanumeric_literal?(literal)

            literal.start_with?(':') || literal.end_with?(',')
          end
        end

        def non_alphanumeric_literal?(literal)
          !/[[:alnum:]]/.match?(literal)
        end
      end
    end
  end
end
