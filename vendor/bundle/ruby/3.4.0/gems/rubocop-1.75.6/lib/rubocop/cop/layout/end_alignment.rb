# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether the end keywords are aligned properly.
      #
      # Three modes are supported through the `EnforcedStyleAlignWith`
      # configuration parameter:
      #
      # If it's set to `keyword` (which is the default), the `end`
      # shall be aligned with the start of the keyword (if, class, etc.).
      #
      # If it's set to `variable` the `end` shall be aligned with the
      # left-hand-side of the variable assignment, if there is one.
      #
      # If it's set to `start_of_line`, the `end` shall be aligned with the
      # start of the line where the matching keyword appears.
      #
      # This `Layout/EndAlignment` cop aligns with keywords (e.g. `if`, `while`, `case`)
      # by default. On the other hand, `Layout/BeginEndAlignment` cop aligns with
      # `EnforcedStyleAlignWith: start_of_line` by default due to `||= begin` tends
      # to align with the start of the line. `Layout/DefEndAlignment` cop also aligns with
      # `EnforcedStyleAlignWith: start_of_line` by default.
      # These style can be configured by each cop.
      #
      # @example EnforcedStyleAlignWith: keyword (default)
      #   # bad
      #
      #   variable = if true
      #       end
      #
      #   # good
      #
      #   variable = if true
      #              end
      #
      #   variable =
      #     if true
      #     end
      #
      # @example EnforcedStyleAlignWith: variable
      #   # bad
      #
      #   variable = if true
      #       end
      #
      #   # good
      #
      #   variable = if true
      #   end
      #
      #   variable =
      #     if true
      #     end
      #
      # @example EnforcedStyleAlignWith: start_of_line
      #   # bad
      #
      #   variable = if true
      #       end
      #
      #   puts(if true
      #        end)
      #
      #   # good
      #
      #   variable = if true
      #   end
      #
      #   puts(if true
      #   end)
      #
      #   variable =
      #     if true
      #     end
      class EndAlignment < Base
        include CheckAssignment
        include EndKeywordAlignment
        include RangeHelp
        extend AutoCorrector

        def on_class(node)
          check_other_alignment(node)
        end

        def on_sclass(node)
          if node.parent&.assignment?
            check_asgn_alignment(node.parent, node)
          else
            check_other_alignment(node)
          end
        end

        def on_module(node)
          check_other_alignment(node)
        end

        def on_if(node)
          check_other_alignment(node) unless node.ternary?
        end

        def on_while(node)
          check_other_alignment(node)
        end

        def on_until(node)
          check_other_alignment(node)
        end

        def on_case(node)
          if node.argument?
            check_asgn_alignment(node.parent, node)
          else
            check_other_alignment(node)
          end
        end
        alias on_case_match on_case

        private

        def autocorrect(corrector, node)
          AlignmentCorrector.align_end(corrector, processed_source, node, alignment_node(node))
        end

        def check_assignment(node, rhs)
          # If there are method calls chained to the right hand side of the
          # assignment, we let rhs be the receiver of those method calls before
          # we check if it's an if/unless/while/until.
          return unless (rhs = first_part_of_call_chain(rhs))
          return unless rhs.conditional?
          return if rhs.if_type? && rhs.ternary?

          check_asgn_alignment(node, rhs)
        end

        def check_asgn_alignment(outer_node, inner_node)
          align_with = {
            keyword: inner_node.loc.keyword,
            start_of_line: start_line_range(inner_node),
            variable: asgn_variable_align_with(outer_node, inner_node)
          }

          check_end_kw_alignment(inner_node, align_with)
          ignore_node(inner_node)
        end

        def asgn_variable_align_with(outer_node, inner_node)
          expr = outer_node.source_range

          if line_break_before_keyword?(expr, inner_node)
            inner_node.loc.keyword
          else
            range_between(expr.begin_pos, inner_node.loc.keyword.end_pos)
          end
        end

        def check_other_alignment(node)
          align_with = {
            keyword: node.loc.keyword,
            variable: node.loc.keyword,
            start_of_line: start_line_range(node)
          }
          check_end_kw_alignment(node, align_with)
        end

        def alignment_node(node)
          case style
          when :keyword
            node
          when :variable
            align_to = alignment_node_for_variable_style(node)

            while (parent = align_to.parent) && parent.send_type? && same_line?(align_to, parent)
              align_to = parent
            end

            align_to
          else
            start_line_range(node)
          end
        end

        def alignment_node_for_variable_style(node)
          if node.type?(:case, :case_match) && node.argument? &&
             same_line?(node, node.parent)
            return node.parent
          end

          assignment = assignment_or_operator_method(node)

          if assignment && !line_break_before_keyword?(assignment.source_range, node)
            assignment
          else
            # Fall back to 'keyword' style if this node is not on the RHS of an
            # assignment, or if it is but there's a line break between LHS and
            # RHS.
            node
          end
        end

        def assignment_or_operator_method(node)
          node.ancestors.find do |ancestor|
            ancestor.assignment_or_similar? || (ancestor.send_type? && ancestor.operator_method?)
          end
        end
      end
    end
  end
end
