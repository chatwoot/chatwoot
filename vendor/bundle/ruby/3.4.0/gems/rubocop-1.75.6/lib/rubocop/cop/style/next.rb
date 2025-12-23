# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Use `next` to skip iteration instead of a condition at the end.
      #
      # @example EnforcedStyle: skip_modifier_ifs (default)
      #   # bad
      #   [1, 2].each do |a|
      #     if a == 1
      #       puts a
      #     end
      #   end
      #
      #   # good
      #   [1, 2].each do |a|
      #     next unless a == 1
      #     puts a
      #   end
      #
      #   # good
      #   [1, 2].each do |a|
      #     puts a if a == 1
      #   end
      #
      # @example EnforcedStyle: always
      #   # With `always` all conditions at the end of an iteration needs to be
      #   # replaced by next - with `skip_modifier_ifs` the modifier if like
      #   # this one are ignored: `[1, 2].each { |a| puts a if a == 1 }`
      #
      #   # bad
      #   [1, 2].each do |a|
      #     puts a if a == 1
      #   end
      #
      #   # bad
      #   [1, 2].each do |a|
      #     if a == 1
      #       puts a
      #     end
      #   end
      #
      #   # good
      #   [1, 2].each do |a|
      #     next unless a == 1
      #     puts a
      #   end
      #
      # @example AllowConsecutiveConditionals: false (default)
      #   # bad
      #   [1, 2].each do |a|
      #     if a == 1
      #       puts a
      #     end
      #     if a == 2
      #       puts a
      #     end
      #   end
      #
      #   # good
      #   [1, 2].each do |a|
      #     if a == 1
      #       puts a
      #     end
      #     next unless a == 2
      #     puts a
      #   end
      #
      # @example AllowConsecutiveConditionals: true
      #   # good
      #   [1, 2].each do |a|
      #     if a == 1
      #       puts a
      #     end
      #     if a == 2
      #       puts a
      #     end
      #   end
      #
      class Next < Base
        include ConfigurableEnforcedStyle
        include MinBodyLength
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `next` to skip iteration.'
        EXIT_TYPES = %i[break return].freeze

        def self.autocorrect_incompatible_with
          [Style::SafeNavigation]
        end

        def on_new_investigation
          # When correcting nested offenses, we need to keep track of how much
          # we have adjusted the indentation of each line
          @reindented_lines = Hash.new(0)
        end

        def on_block(node)
          return unless node.send_node.call_type? && node.send_node.enumerator_method?

          check(node)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        def on_while(node)
          check(node)
        end
        alias on_until on_while
        alias on_for on_while

        private

        def check(node)
          return unless node.body && ends_with_condition?(node.body)

          offending_node = offense_node(node.body)

          return if allowed_consecutive_conditionals? &&
                    consecutive_conditionals?(offending_node)

          add_offense(offense_location(offending_node)) do |corrector|
            if offending_node.modifier_form?
              autocorrect_modifier(corrector, offending_node)
            else
              autocorrect_block(corrector, offending_node)
            end
          end
        end

        def ends_with_condition?(body)
          return true if simple_if_without_break?(body)

          body.begin_type? && simple_if_without_break?(body.children.last)
        end

        def simple_if_without_break?(node)
          return false unless if_without_else?(node)
          return false if if_else_children?(node)
          return false if allowed_modifier_if?(node)

          !exit_body_type?(node)
        end

        def allowed_modifier_if?(node)
          if node.modifier_form?
            style == :skip_modifier_ifs
          else
            !min_body_length?(node)
          end
        end

        def if_else_children?(node)
          node.each_child_node(:if).any?(&:else?)
        end

        def if_without_else?(node)
          node&.if_type? && !node.ternary? && !node.else?
        end

        def exit_body_type?(node)
          return false unless node.if_branch

          EXIT_TYPES.include?(node.if_branch.type)
        end

        def offense_node(body)
          *_, condition = *body

          condition&.if_type? ? condition : body
        end

        def offense_location(offense_node)
          offense_begin_pos = offense_node.source_range.begin
          offense_begin_pos.join(offense_node.condition.source_range)
        end

        def autocorrect_modifier(corrector, node)
          body = node.if_branch || node.else_branch

          replacement =
            "next #{node.inverse_keyword} #{node.condition.source}\n" \
            "#{' ' * node.source_range.column}#{body.source}"

          corrector.replace(node, replacement)
        end

        def autocorrect_block(corrector, node)
          next_code = "next #{node.inverse_keyword} #{node.condition.source}"

          corrector.insert_before(node, next_code)

          corrector.remove(cond_range(node, node.condition))
          corrector.remove(end_range(node))

          lines = reindentable_lines(node)

          return if lines.empty?

          reindent(lines, node.condition, corrector)
        end

        def cond_range(node, cond)
          end_pos = if node.loc.begin
                      node.loc.begin.end_pos # after "then"
                    else
                      cond.source_range.end_pos
                    end

          range_between(node.source_range.begin_pos, end_pos)
        end

        def end_range(node)
          source_buffer = node.source_range.source_buffer
          end_pos = node.loc.end.end_pos
          begin_pos = node.loc.end.begin_pos - node.loc.end.column
          begin_pos -= 1 if end_followed_by_whitespace_only?(source_buffer, end_pos)

          range_between(begin_pos, end_pos)
        end

        def end_followed_by_whitespace_only?(source_buffer, end_pos)
          /\A\s*$/.match?(source_buffer.source[end_pos..])
        end

        def reindentable_lines(node)
          buffer = node.source_range.source_buffer

          # end_range starts with the final newline of the if body
          lines = (node.source_range.line + 1)...node.loc.end.line
          lines = lines.to_a - heredoc_lines(node)
          # Skip blank lines
          lines.reject { |lineno| /\A\s*\z/.match?(buffer.source_line(lineno)) }
        end

        # Adjust indentation of `lines` to match `node`
        def reindent(lines, node, corrector)
          range  = node.source_range
          buffer = range.source_buffer

          target_indent = range.source_line =~ /\S/
          delta = actual_indent(lines, buffer) - target_indent
          lines.each { |lineno| reindent_line(corrector, lineno, delta, buffer) }
        end

        def actual_indent(lines, buffer)
          lines.map { |lineno| buffer.source_line(lineno) =~ /\S/ }.min
        end

        def heredoc_lines(node)
          node.each_node(:dstr)
              .select(&:heredoc?)
              .map { |n| n.loc.heredoc_body }
              .flat_map { |b| (b.line...b.last_line).to_a }
        end

        def reindent_line(corrector, lineno, delta, buffer)
          adjustment = delta + @reindented_lines[lineno]
          @reindented_lines[lineno] = adjustment

          corrector.remove_leading(buffer.line_range(lineno), adjustment) if adjustment.positive?
        end

        def consecutive_conditionals?(if_node)
          if_node.parent&.begin_type? && if_node.left_sibling&.if_type?
        end

        def allowed_consecutive_conditionals?
          cop_config.fetch('AllowConsecutiveConditionals', false)
        end
      end
    end
  end
end
