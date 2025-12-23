# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for overwriting an exception with an exception result by use ``rescue =>``.
      #
      # You intended to write as `rescue StandardError`.
      # However, you have written `rescue => StandardError`.
      # In that case, the result of `rescue` will overwrite `StandardError`.
      #
      # @example
      #
      #   # bad
      #   begin
      #     something
      #   rescue => StandardError
      #   end
      #
      #   # good
      #   begin
      #     something
      #   rescue StandardError
      #   end
      #
      class ConstantOverwrittenInRescue < Base
        extend AutoCorrector
        include RangeHelp

        MSG = '`%<constant>s` is overwritten by `rescue =>`.'

        # @!method overwritten_constant(node)
        def_node_matcher :overwritten_constant, <<~PATTERN
          (resbody nil? (casgn nil? $_) nil?)
        PATTERN

        def self.autocorrect_incompatible_with
          [Naming::RescuedExceptionsVariableName, Style::RescueStandardError]
        end

        def on_resbody(node)
          return unless (constant = overwritten_constant(node))

          add_offense(node.loc.assoc, message: format(MSG, constant: constant)) do |corrector|
            corrector.remove(range_between(node.loc.keyword.end_pos, node.loc.assoc.end_pos))
          end
        end
      end
    end
  end
end
