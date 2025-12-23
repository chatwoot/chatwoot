# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for strings that are just an interpolated expression.
      #
      # @safety
      #   Autocorrection is unsafe because when calling a destructive method to string,
      #   the resulting string may have different behavior or raise `FrozenError`.
      #
      #   [source,ruby]
      #   ----
      #   x = 'a'
      #   y = "#{x}"
      #   y << 'b'   # return 'ab'
      #   x          # return 'a'
      #   y = x.to_s
      #   y << 'b'   # return 'ab'
      #   x          # return 'ab'
      #
      #   x = 'a'.freeze
      #   y = "#{x}"
      #   y << 'b'   # return 'ab'.
      #   y = x.to_s
      #   y << 'b'   # raise `FrozenError`.
      #   ----
      #
      # @example
      #
      #   # bad
      #   "#{@var}"
      #
      #   # good
      #   @var.to_s
      #
      #   # good if @var is already a String
      #   @var
      class RedundantInterpolation < Base
        include PercentLiteral
        extend AutoCorrector

        MSG = 'Prefer `to_s` over string interpolation.'

        def self.autocorrect_incompatible_with
          [Style::LineEndConcatenation]
        end

        def on_dstr(node)
          return unless single_interpolation?(node)

          add_offense(node) do |corrector|
            embedded_node = node.children.first

            if variable_interpolation?(embedded_node)
              autocorrect_variable_interpolation(corrector, embedded_node, node)
            elsif single_variable_interpolation?(embedded_node)
              autocorrect_single_variable_interpolation(corrector, embedded_node, node)
            else
              autocorrect_other(corrector, embedded_node, node)
            end
          end
        end

        private

        def single_interpolation?(node)
          node.children.one? &&
            interpolation?(node.children.first) &&
            !implicit_concatenation?(node) &&
            !embedded_in_percent_array?(node)
        end

        def single_variable_interpolation?(node)
          return false unless node.children.one?

          first_child = node.children.first

          variable_interpolation?(first_child) ||
            (first_child.send_type? && !first_child.operator_method?)
        end

        def interpolation?(node)
          variable_interpolation?(node) || node.begin_type?
        end

        def variable_interpolation?(node)
          node.variable? || node.reference?
        end

        def implicit_concatenation?(node)
          node.parent&.dstr_type?
        end

        def embedded_in_percent_array?(node)
          node.parent&.array_type? && percent_literal?(node.parent)
        end

        def autocorrect_variable_interpolation(corrector, embedded_node, node)
          replacement = "#{embedded_node.source}.to_s"

          corrector.replace(node, replacement)
        end

        def autocorrect_single_variable_interpolation(corrector, embedded_node, node)
          embedded_var = embedded_node.children.first

          source = if require_parentheses?(embedded_var)
                     receiver = range_between(
                       embedded_var.source_range.begin_pos, embedded_var.loc.selector.end_pos
                     )
                     arguments = embedded_var.arguments.map(&:source).join(', ')

                     "#{receiver.source}(#{arguments})"
                   else
                     embedded_var.source
                   end

          corrector.replace(node, "#{source}.to_s")
        end

        def autocorrect_other(corrector, embedded_node, node)
          loc = node.loc
          embedded_loc = embedded_node.loc

          corrector.replace(loc.begin, '')
          corrector.replace(loc.end, '')
          corrector.replace(embedded_loc.begin, '(')
          corrector.replace(embedded_loc.end, ').to_s')
        end

        def require_parentheses?(node)
          node.send_type? && !node.arguments.count.zero? && !node.parenthesized_call?
        end
      end
    end
  end
end
