# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Finds regular expressions with dynamic components that are all constants.
      #
      # Ruby allocates a new Regexp object every time it executes a code containing such
      # a regular expression. It is more efficient to extract it into a constant,
      # memoize it, or add an `/o` option to perform `#{}` interpolation only once and
      # reuse that Regexp object.
      #
      # @example
      #
      #   # bad
      #   def tokens(pattern)
      #     pattern.scan(TOKEN).reject { |token| token.match?(/\A#{SEPARATORS}\Z/) }
      #   end
      #
      #   # good
      #   ALL_SEPARATORS = /\A#{SEPARATORS}\Z/
      #   def tokens(pattern)
      #     pattern.scan(TOKEN).reject { |token| token.match?(ALL_SEPARATORS) }
      #   end
      #
      #   # good
      #   def tokens(pattern)
      #     pattern.scan(TOKEN).reject { |token| token.match?(/\A#{SEPARATORS}\Z/o) }
      #   end
      #
      #   # good
      #   def separators
      #     @separators ||= /\A#{SEPARATORS}\Z/
      #   end
      #
      class ConstantRegexp < Base
        extend AutoCorrector

        MSG = 'Extract this regexp into a constant, memoize it, or append an `/o` option to its options.'

        def self.autocorrect_incompatible_with
          [RegexpMatch]
        end

        def on_regexp(node)
          return if within_allowed_assignment?(node) || !include_interpolated_const?(node) || node.single_interpolation?

          add_offense(node) do |corrector|
            corrector.insert_after(node, 'o')
          end
        end

        private

        def within_allowed_assignment?(node)
          node.each_ancestor(:casgn, :or_asgn).any?
        end

        def_node_matcher :regexp_escape?, <<~PATTERN
          (send
            (const nil? :Regexp) :escape const_type?)
        PATTERN

        def include_interpolated_const?(node)
          return false unless node.interpolation?

          node.each_child_node(:begin).all? do |begin_node|
            inner_node = begin_node.children.first
            inner_node && (inner_node.const_type? || regexp_escape?(inner_node))
          end
        end
      end
    end
  end
end
