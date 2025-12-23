# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for quotes and commas in %w, e.g. `%w('foo', "bar")`
      #
      # It is more likely that the additional characters are unintended (for
      # example, mistranslating an array of literals to percent string notation)
      # rather than meant to be part of the resulting strings.
      #
      # @safety
      #   The cop is unsafe because the correction changes the values in the array
      #   and that might have been done purposely.
      #
      #   [source,ruby]
      #   ----
      #   %w('foo', "bar") #=> ["'foo',", '"bar"']
      #   %w(foo bar)      #=> ['foo', 'bar']
      #   ----
      #
      # @example
      #
      #   # bad
      #   %w('foo', "bar")
      #
      #   # good
      #   %w(foo bar)
      class PercentStringArray < Base
        include PercentLiteral
        extend AutoCorrector

        QUOTES_AND_COMMAS = [/,$/, /^'.*'$/, /^".*"$/].freeze
        LEADING_QUOTE = /^['"]/.freeze
        TRAILING_QUOTE = /['"]?,?$/.freeze

        MSG = "Within `%w`/`%W`, quotes and ',' are unnecessary and may be " \
              'unwanted in the resulting strings.'

        def on_array(node)
          process(node, '%w', '%W')
        end

        def on_percent_literal(node)
          return unless contains_quotes_or_commas?(node)

          add_offense(node) do |corrector|
            node.each_value do |value|
              range = value.source_range

              match = range.source.match(TRAILING_QUOTE)
              corrector.remove_trailing(range, match[0].length) if match

              corrector.remove_leading(range, 1) if LEADING_QUOTE.match?(range.source)
            end
          end
        end

        private

        def contains_quotes_or_commas?(node)
          node.values.any? do |value|
            literal = value.children.first.to_s.scrub

            # To avoid likely false positives (e.g. a single ' or ")
            next if literal.gsub(/[^[[:alnum:]]]/, '').empty?

            QUOTES_AND_COMMAS.any? { |pat| literal.match?(pat) }
          end
        end
      end
    end
  end
end
