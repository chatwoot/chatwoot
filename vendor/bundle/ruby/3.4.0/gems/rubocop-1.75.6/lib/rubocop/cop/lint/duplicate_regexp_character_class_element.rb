# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for duplicate elements in `Regexp` character classes.
      #
      # @example
      #
      #   # bad
      #   r = /[xyx]/
      #
      #   # bad
      #   r = /[0-9x0-9]/
      #
      #   # good
      #   r = /[xy]/
      #
      #   # good
      #   r = /[0-9x]/
      class DuplicateRegexpCharacterClassElement < Base
        include RangeHelp
        extend AutoCorrector

        MSG_REPEATED_ELEMENT = 'Duplicate element inside regexp character class'

        OCTAL_DIGITS_AFTER_ESCAPE = 2

        def on_regexp(node)
          each_repeated_character_class_element_loc(node) do |loc|
            add_offense(loc, message: MSG_REPEATED_ELEMENT) do |corrector|
              corrector.remove(loc)
            end
          end
        end

        def each_repeated_character_class_element_loc(node)
          node.parsed_tree&.each_expression do |expr|
            next if skip_expression?(expr)

            seen = Set.new
            group_expressions(node, expr.expressions) do |group|
              group_source = group.map(&:to_s).join

              yield source_range(group) if seen.include?(group_source)

              seen << group_source
            end
          end
        end

        private

        def group_expressions(node, expressions)
          # Create a mutable list to simplify state tracking while we iterate.
          expressions = expressions.to_a

          until expressions.empty?
            # With we may need to compose a group of multiple expressions.
            group = [expressions.shift]
            next if within_interpolation?(node, group.first)

            # With regexp_parser < 2.7 escaped octal sequences may be up to 3
            # separate expressions ("\\0", "0", "1").
            pop_octal_digits(group, expressions) if escaped_octal?(group.first.to_s)

            yield(group)
          end
        end

        def pop_octal_digits(current_child, expressions)
          OCTAL_DIGITS_AFTER_ESCAPE.times do
            next_child = expressions.first
            break unless octal?(next_child.to_s)

            current_child << expressions.shift
          end
        end

        def source_range(children)
          return children.first.expression if children.size == 1

          range_between(
            children.first.expression.begin_pos,
            children.last.expression.begin_pos + children.last.to_s.length
          )
        end

        def skip_expression?(expr)
          expr.type != :set || expr.token == :intersection
        end

        # Since we blank interpolations with a space for every char of the interpolation, we would
        # mark every space (except the first) as duplicate if we do not skip regexp_parser nodes
        # that are within an interpolation.
        def within_interpolation?(node, child)
          parse_tree_child_loc = child.expression

          interpolation_locs(node).any? { |il| il.overlaps?(parse_tree_child_loc) }
        end

        def escaped_octal?(string)
          string.length == 2 && string[0] == '\\' && octal?(string[1])
        end

        def octal?(char)
          ('0'..'7').cover?(char)
        end

        def interpolation_locs(node)
          @interpolation_locs ||= {}

          # Cache by loc, not by regexp content, as content can be repeated in multiple patterns
          key = node.loc

          @interpolation_locs[key] ||= node.children.select(&:begin_type?).map(&:source_range)
        end
      end
    end
  end
end
