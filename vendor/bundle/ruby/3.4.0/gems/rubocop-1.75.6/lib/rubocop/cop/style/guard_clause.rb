# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Use a guard clause instead of wrapping the code inside a conditional
      # expression
      #
      # A condition with an `elsif` or `else` branch is allowed unless
      # one of `return`, `break`, `next`, `raise`, or `fail` is used
      # in the body of the conditional expression.
      #
      # NOTE: Autocorrect works in most cases except with if-else statements
      #   that contain logical operators such as `foo || raise('exception')`
      #
      # @example
      #   # bad
      #   def test
      #     if something
      #       work
      #     end
      #   end
      #
      #   # good
      #   def test
      #     return unless something
      #
      #     work
      #   end
      #
      #   # also good
      #   def test
      #     work if something
      #   end
      #
      #   # bad
      #   if something
      #     raise 'exception'
      #   else
      #     ok
      #   end
      #
      #   # good
      #   raise 'exception' if something
      #   ok
      #
      #   # bad
      #   if something
      #     foo || raise('exception')
      #   else
      #     ok
      #   end
      #
      #   # good
      #   foo || raise('exception') if something
      #   ok
      #
      #   # bad
      #   define_method(:test) do
      #     if something
      #       work
      #     end
      #   end
      #
      #   # good
      #   define_method(:test) do
      #     return unless something
      #
      #     work
      #   end
      #
      #   # also good
      #   define_method(:test) do
      #     work if something
      #   end
      #
      # @example AllowConsecutiveConditionals: false (default)
      #   # bad
      #   def test
      #     if foo?
      #       work
      #     end
      #
      #     if bar?  # <- reports an offense
      #       work
      #     end
      #   end
      #
      # @example AllowConsecutiveConditionals: true
      #   # good
      #   def test
      #     if foo?
      #       work
      #     end
      #
      #     if bar?
      #       work
      #     end
      #   end
      #
      #   # bad
      #   def test
      #     if foo?
      #       work
      #     end
      #
      #     do_something
      #
      #     if bar?  # <- reports an offense
      #       work
      #     end
      #   end
      #
      class GuardClause < Base
        extend AutoCorrector
        include RangeHelp
        include MinBodyLength
        include StatementModifier

        MSG = 'Use a guard clause (`%<example>s`) instead of wrapping the ' \
              'code inside a conditional expression.'

        def on_def(node)
          body = node.body

          return unless body

          check_ending_body(body)
        end
        alias on_defs on_def

        def on_block(node)
          return unless node.method?(:define_method) || node.method?(:define_singleton_method)

          on_def(node)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        def on_if(node)
          return if accepted_form?(node)

          if (guard_clause = node.if_branch&.guard_clause?)
            kw = node.loc.keyword.source
            guard = :if
          elsif (guard_clause = node.else_branch&.guard_clause?)
            kw = node.inverse_keyword
            guard = :else
          else
            return
          end

          guard = nil if and_or_guard_clause?(guard_clause)

          register_offense(node, guard_clause_source(guard_clause), kw, guard)
        end

        private

        def check_ending_body(body)
          return if body.nil?

          if body.if_type?
            check_ending_if(body)
          elsif body.begin_type?
            final_expression = body.children.last
            check_ending_if(final_expression) if final_expression&.if_type?
          end
        end

        def check_ending_if(node)
          return if accepted_form?(node, ending: true) || !min_body_length?(node)
          return if allowed_consecutive_conditionals? &&
                    consecutive_conditionals?(node.parent, node)

          register_offense(node, 'return', node.inverse_keyword)

          check_ending_body(node.if_branch)
        end

        def consecutive_conditionals?(parent, node)
          parent.each_child_node.inject(false) do |if_type, child|
            break if_type if node == child

            child.if_type?
          end
        end

        def register_offense(node, scope_exiting_keyword, conditional_keyword, guard = nil)
          condition, = node.node_parts
          example = [scope_exiting_keyword, conditional_keyword, condition.source].join(' ')
          if too_long_for_single_line?(node, example)
            return if trivial?(node)

            example = "#{conditional_keyword} #{condition.source}; #{scope_exiting_keyword}; end"
            replacement = <<~RUBY.chomp
              #{conditional_keyword} #{condition.source}
                #{scope_exiting_keyword}
              end
            RUBY
          end

          add_offense(node.loc.keyword, message: format(MSG, example: example)) do |corrector|
            next if node.else? && guard.nil?

            autocorrect(corrector, node, condition, replacement || example, guard)
          end
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def autocorrect(corrector, node, condition, replacement, guard)
          corrector.replace(node.loc.keyword.join(condition.source_range), replacement)

          if_branch = node.if_branch
          else_branch = node.else_branch

          corrector.replace(node.loc.begin, "\n") if node.then?

          if if_branch&.send_type? && heredoc?(if_branch.last_argument)
            autocorrect_heredoc_argument(corrector, node, if_branch, else_branch, guard)
          elsif else_branch&.send_type? && heredoc?(else_branch.last_argument)
            autocorrect_heredoc_argument(corrector, node, else_branch, if_branch, guard)
          else
            corrector.remove(node.loc.end)
            return unless node.else?

            corrector.remove(node.loc.else)
            corrector.remove(range_of_branch_to_remove(node, guard))
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def heredoc?(argument)
          argument.respond_to?(:heredoc?) && argument.heredoc?
        end

        def autocorrect_heredoc_argument(corrector, node, heredoc_branch, leave_branch, guard)
          remove_whole_lines(corrector, node.loc.end)
          return unless node.else?

          remove_whole_lines(corrector, leave_branch.source_range)
          remove_whole_lines(corrector, node.loc.else)
          remove_whole_lines(corrector, range_of_branch_to_remove(node, guard))
          corrector.insert_after(
            heredoc_branch.last_argument.loc.heredoc_end, "\n#{leave_branch.source}"
          )
        end

        def range_of_branch_to_remove(node, guard)
          branch = case guard
                   when :if then node.if_branch
                   when :else then node.else_branch
                   end

          branch.source_range
        end

        def guard_clause_source(guard_clause)
          if and_or_guard_clause?(guard_clause)
            guard_clause.parent.source
          else
            guard_clause.source
          end
        end

        def and_or_guard_clause?(guard_clause)
          parent = guard_clause.parent
          parent.operator_keyword?
        end

        def too_long_for_single_line?(node, example)
          max = max_line_length
          max && node.source_range.column + example.length > max
        end

        def accepted_form?(node, ending: false)
          accepted_if?(node, ending) || node.condition.multiline? || node.parent&.assignment?
        end

        def trivial?(node)
          return false unless node.if_branch

          node.branches.one? && !node.if_branch.if_type? && !node.if_branch.begin_type?
        end

        def accepted_if?(node, ending)
          return true if node.modifier_form? || node.ternary? || node.elsif_conditional? ||
                         assigned_lvar_used_in_if_branch?(node)

          if ending
            node.else?
          else
            !node.else? || node.elsif?
          end
        end

        def assigned_lvar_used_in_if_branch?(node)
          return false unless (if_branch = node.if_branch)

          assigned_lvars_in_condition = node.condition.each_descendant(:lvasgn).map do |lvasgn|
            lvar_name, = *lvasgn
            lvar_name.to_s
          end
          used_lvars_in_branch = if_branch.each_descendant(:lvar).map(&:source) || []

          (assigned_lvars_in_condition & used_lvars_in_branch).any?
        end

        def remove_whole_lines(corrector, range)
          corrector.remove(range_by_whole_lines(range, include_final_newline: true))
        end

        def allowed_consecutive_conditionals?
          cop_config.fetch('AllowConsecutiveConditionals', false)
        end
      end
    end
  end
end
