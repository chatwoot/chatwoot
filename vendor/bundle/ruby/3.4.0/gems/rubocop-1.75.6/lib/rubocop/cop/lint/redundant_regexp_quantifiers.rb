# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for redundant quantifiers inside `Regexp` literals.
      #
      # It is always allowed when interpolation is used in a regexp literal,
      # because it's unknown what kind of string will be expanded as a result:
      #
      # [source,ruby]
      # ----
      # /(?:a*#{interpolation})?/x
      # ----
      #
      # @example
      #   # bad
      #   /(?:x+)+/
      #
      #   # good
      #   /(?:x)+/
      #
      #   # good
      #   /(?:x+)/
      #
      #   # bad
      #   /(?:x+)?/
      #
      #   # good
      #   /(?:x)*/
      #
      #   # good
      #   /(?:x*)/
      class RedundantRegexpQuantifiers < Base
        include RangeHelp
        extend AutoCorrector

        MSG_REDUNDANT_QUANTIFIER = 'Replace redundant quantifiers ' \
                                   '`%<inner_quantifier>s` and `%<outer_quantifier>s` ' \
                                   'with a single `%<replacement>s`.'

        def on_regexp(node)
          return if node.interpolation?

          each_redundantly_quantified_pair(node) do |group, child|
            replacement = merged_quantifier(group, child)
            add_offense(
              quantifier_range(group, child),
              message: message(group, child, replacement)
            ) do |corrector|
              # drop outer quantifier
              corrector.replace(group.loc.quantifier, '')
              # replace inner quantifier
              corrector.replace(child.loc.quantifier, replacement)
            end
          end
        end

        private

        def each_redundantly_quantified_pair(node)
          seen = Set.new
          node.parsed_tree&.each_expression do |(expr)|
            next if seen.include?(expr) || !redundant_group?(expr) || !mergeable_quantifier(expr)

            expr.each_expression do |(subexp)|
              seen << subexp
              break unless redundantly_quantifiable?(subexp)

              yield(expr, subexp) if mergeable_quantifier(subexp)
            end
          end
        end

        def redundant_group?(expr)
          expr.is?(:passive, :group) && expr.count { |child| child.type != :free_space } == 1
        end

        def redundantly_quantifiable?(node)
          redundant_group?(node) || character_set?(node) || node.terminal?
        end

        def character_set?(expr)
          expr.is?(:character, :set)
        end

        def mergeable_quantifier(expr)
          # Merging reluctant or possessive quantifiers would be more complex,
          # and Ruby does not emit warnings for these cases.
          return unless expr.quantifier&.greedy?

          # normalize quantifiers, e.g. "{1,}" => "+"
          case expr.quantity
          when [0, -1]
            '*'
          when [0, 1]
            '?'
          when [1, -1]
            '+'
          end
        end

        def merged_quantifier(exp1, exp2)
          quantifier1 = mergeable_quantifier(exp1)
          quantifier2 = mergeable_quantifier(exp2)
          if quantifier1 == quantifier2
            # (?:a+)+ equals (?:a+) ; (?:a*)* equals (?:a*) ; # (?:a?)? equals (?:a?)
            quantifier1
          else
            # (?:a+)*, (?:a+)?, (?:a*)+, (?:a*)?, (?:a?)+, (?:a?)* - all equal (?:a*)
            '*'
          end
        end

        def quantifier_range(group, child)
          range_between(child.loc.quantifier.begin_pos, group.loc.quantifier.end_pos)
        end

        def message(group, child, replacement)
          format(
            MSG_REDUNDANT_QUANTIFIER,
            inner_quantifier: child.quantifier.to_s,
            outer_quantifier: group.quantifier.to_s,
            replacement: replacement
          )
        end
      end
    end
  end
end
