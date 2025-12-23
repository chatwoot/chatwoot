# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether the end keywords of method definitions are
      # aligned properly.
      #
      # Two modes are supported through the EnforcedStyleAlignWith configuration
      # parameter. If it's set to `start_of_line` (which is the default), the
      # `end` shall be aligned with the start of the line where the `def`
      # keyword is. If it's set to `def`, the `end` shall be aligned with the
      # `def` keyword.
      #
      # @example EnforcedStyleAlignWith: start_of_line (default)
      #   # bad
      #
      #   private def foo
      #               end
      #
      #   # good
      #
      #   private def foo
      #   end
      #
      # @example EnforcedStyleAlignWith: def
      #   # bad
      #
      #   private def foo
      #               end
      #
      #   # good
      #
      #   private def foo
      #           end
      class DefEndAlignment < Base
        include EndKeywordAlignment
        include RangeHelp
        extend AutoCorrector

        MSG = '`end` at %d, %d is not aligned with `%s` at %d, %d.'

        def on_def(node)
          check_end_kw_in_node(node)
        end
        alias on_defs on_def

        def on_send(node)
          return unless node.def_modifier?

          method_def = node.each_descendant(:any_def).first
          expr = node.source_range

          line_start = range_between(expr.begin_pos, method_def.loc.keyword.end_pos)
          align_with = { def: method_def.loc.keyword, start_of_line: line_start }

          check_end_kw_alignment(method_def, align_with)
          ignore_node(method_def) # Don't check the same `end` again.
        end

        private

        def autocorrect(corrector, node)
          if style == :start_of_line && node.parent&.send_type?
            AlignmentCorrector.align_end(corrector, processed_source, node, node.parent)
          else
            AlignmentCorrector.align_end(corrector, processed_source, node, node)
          end
        end
      end
    end
  end
end
