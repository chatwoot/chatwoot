# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for mixed-case character ranges since they include likely unintended characters.
      #
      # Offenses are registered for regexp character classes like `/[A-z]/`
      # as well as range objects like `('A'..'z')`.
      #
      # NOTE: `Range` objects cannot be autocorrected.
      #
      # @safety
      #   The cop autocorrects regexp character classes
      #   by replacing one character range with two: `A-z` becomes `A-Za-z`.
      #   In most cases this is probably what was originally intended
      #   but it changes the regexp to no longer match symbols it used to include.
      #   For this reason, this cop's autocorrect is unsafe (it will
      #   change the behavior of the code).
      #
      # @example
      #
      #   # bad
      #   r = /[A-z]/
      #
      #   # good
      #   r = /[A-Za-z]/
      class MixedCaseRange < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Ranges from upper to lower case ASCII letters may include unintended ' \
              'characters. Instead of `A-z` (which also includes several symbols) ' \
              'specify each range individually: `A-Za-z` and individually specify any symbols.'
        RANGES = [('a'..'z').freeze, ('A'..'Z').freeze].freeze

        def on_irange(node)
          return unless node.children.compact.all?(&:str_type?)
          return if node.begin.nil? || node.end.nil?

          add_offense(node) if unsafe_range?(node.begin.value, node.end.value)
        end
        alias on_erange on_irange

        def on_regexp(node)
          each_unsafe_regexp_range(node) do |loc|
            next unless (replacement = regexp_range(loc.source))

            add_offense(loc) do |corrector|
              corrector.replace(loc, replacement)
            end
          end
        end

        def each_unsafe_regexp_range(node)
          node.parsed_tree&.each_expression do |expr|
            next if skip_expression?(expr)

            range_pairs(expr).reject do |range_start, range_end|
              next if skip_range?(range_start, range_end)

              next unless unsafe_range?(range_start.text, range_end.text)

              yield(build_source_range(range_start, range_end))
            end
          end
        end

        private

        def build_source_range(range_start, range_end)
          range_between(range_start.expression.begin_pos, range_end.expression.end_pos)
        end

        def range_for(char)
          RANGES.detect do |range|
            range.include?(char)
          end
        end

        def range_pairs(expr)
          expr.expressions.filter_map { |e| [e.expressions[0], e.expressions[1]] if e.type == :set }
        end

        def unsafe_range?(range_start, range_end)
          return false if range_start.length != 1 || range_end.length != 1

          range_for(range_start) != range_for(range_end)
        end

        def skip_expression?(expr)
          !(expr.type == :set && expr.token == :character)
        end

        def skip_range?(range_start, range_end)
          [range_start, range_end].any? do |bound|
            bound&.type != :literal
          end
        end

        def regexp_range(source)
          open, close = source.split('-')
          return unless (open_range = range_for(open))
          return unless (close_range = range_for(close))

          first = [open, open_range.end]
          second = [close_range.begin, close]
          "#{first.uniq.join('-')}#{second.uniq.join('-')}"
        end
      end
    end
  end
end
