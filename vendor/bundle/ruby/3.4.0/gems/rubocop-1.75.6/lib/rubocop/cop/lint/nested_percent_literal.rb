# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for nested percent literals.
      #
      # @example
      #
      #   # bad
      #
      #   # The percent literal for nested_attributes is parsed as four tokens,
      #   # yielding the array [:name, :content, :"%i[incorrectly", :"nested]"].
      #   attributes = {
      #     valid_attributes: %i[name content],
      #     nested_attributes: %i[name content %i[incorrectly nested]]
      #   }
      #
      #   # good
      #
      #   # Neither is incompatible with the bad case, but probably the intended code.
      #   attributes = {
      #     valid_attributes: %i[name content],
      #     nested_attributes: [:name, :content, %i[incorrectly nested]]
      #   }
      #
      #   attributes = {
      #     valid_attributes: %i[name content],
      #     nested_attributes: [:name, :content, [:incorrectly, :nested]]
      #   }
      #
      class NestedPercentLiteral < Base
        include PercentLiteral

        MSG = 'Within percent literals, nested percent literals do not ' \
              'function and may be unwanted in the result.'

        # The array of regular expressions representing percent literals that,
        # if found within a percent literal expression, will cause a
        # NestedPercentLiteral violation to be emitted.
        PERCENT_LITERAL_TYPES = PreferredDelimiters::PERCENT_LITERAL_TYPES
        REGEXES = PERCENT_LITERAL_TYPES.map { |percent_literal| /\A#{percent_literal}\W/ }.freeze

        def on_array(node)
          process(node, *PERCENT_LITERAL_TYPES)
        end

        def on_percent_literal(node)
          add_offense(node) if contains_percent_literals?(node)
        end

        private

        def contains_percent_literals?(node)
          node.each_child_node.any? do |child|
            literal = child.children.first.to_s.scrub
            REGEXES.any? { |regex| literal.match?(regex) }
          end
        end
      end
    end
  end
end
