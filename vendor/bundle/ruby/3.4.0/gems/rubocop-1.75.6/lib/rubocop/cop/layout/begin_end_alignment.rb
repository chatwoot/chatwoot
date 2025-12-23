# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether the end keyword of `begin` is aligned properly.
      #
      # Two modes are supported through the `EnforcedStyleAlignWith` configuration
      # parameter. If it's set to `start_of_line` (which is the default), the
      # `end` shall be aligned with the start of the line where the `begin`
      # keyword is. If it's set to `begin`, the `end` shall be aligned with the
      # `begin` keyword.
      #
      # `Layout/EndAlignment` cop aligns with keywords (e.g. `if`, `while`, `case`)
      # by default. On the other hand, `||= begin` that this cop targets tends to
      # align with the start of the line, it defaults to `EnforcedStyleAlignWith: start_of_line`.
      # These style can be configured by each cop.
      #
      # @example EnforcedStyleAlignWith: start_of_line (default)
      #   # bad
      #   foo ||= begin
      #             do_something
      #           end
      #
      #   # good
      #   foo ||= begin
      #     do_something
      #   end
      #
      # @example EnforcedStyleAlignWith: begin
      #   # bad
      #   foo ||= begin
      #     do_something
      #   end
      #
      #   # good
      #   foo ||= begin
      #             do_something
      #           end
      #
      class BeginEndAlignment < Base
        include EndKeywordAlignment
        extend AutoCorrector

        MSG = '`end` at %d, %d is not aligned with `%s` at %d, %d.'

        def on_kwbegin(node)
          check_begin_alignment(node)
        end

        private

        def check_begin_alignment(node)
          align_with = { begin: node.loc.begin, start_of_line: start_line_range(node) }
          check_end_kw_alignment(node, align_with)
        end

        def autocorrect(corrector, node)
          AlignmentCorrector.align_end(corrector, processed_source, node, alignment_node(node))
        end

        def alignment_node(node)
          case style
          when :begin
            node
          else
            start_line_range(node)
          end
        end
      end
    end
  end
end
