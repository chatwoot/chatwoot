# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks that there are no repeated patterns used in `in` keywords.
      #
      # @example
      #
      #   # bad
      #   case x
      #   in 'first'
      #     do_something
      #   in 'first'
      #     do_something_else
      #   end
      #
      #   # good
      #   case x
      #   in 'first'
      #     do_something
      #   in 'second'
      #     do_something_else
      #   end
      #
      #   # bad - repeated alternate patterns with the same conditions don't depend on the order
      #   case x
      #   in foo | bar
      #     first_method
      #   in bar | foo
      #     second_method
      #   end
      #
      #   # good
      #   case x
      #   in foo | bar
      #     first_method
      #   in bar | baz
      #     second_method
      #   end
      #
      #   # bad - repeated hash patterns with the same conditions don't depend on the order
      #   case x
      #   in foo: a, bar: b
      #     first_method
      #   in bar: b, foo: a
      #     second_method
      #   end
      #
      #   # good
      #   case x
      #   in foo: a, bar: b
      #     first_method
      #   in bar: b, baz: c
      #     second_method
      #   end
      #
      #   # bad - repeated array patterns with elements in the same order
      #   case x
      #   in [foo, bar]
      #     first_method
      #   in [foo, bar]
      #     second_method
      #   end
      #
      #   # good
      #   case x
      #   in [foo, bar]
      #     first_method
      #   in [bar, foo]
      #     second_method
      #   end
      #
      #   # bad - repeated the same patterns and guard conditions
      #   case x
      #   in foo if bar
      #     first_method
      #   in foo if bar
      #     second_method
      #   end
      #
      #   # good
      #   case x
      #   in foo if bar
      #     first_method
      #   in foo if baz
      #     second_method
      #   end
      #
      class DuplicateMatchPattern < Base
        extend TargetRubyVersion

        MSG = 'Duplicate `in` pattern detected.'

        minimum_target_ruby_version 2.7

        def on_case_match(case_node)
          case_node.in_pattern_branches.each_with_object(Set.new) do |in_pattern_node, previous|
            pattern = in_pattern_node.pattern
            next if previous.add?(pattern_identity(pattern))

            add_offense(pattern)
          end
        end

        private

        def pattern_identity(pattern)
          pattern_source = if pattern.type?(:hash_pattern, :match_alt)
                             pattern.children.map(&:source).sort.to_s
                           else
                             pattern.source
                           end

          return pattern_source unless (guard = pattern.parent.children[1])

          pattern_source + guard.source
        end
      end
    end
  end
end
