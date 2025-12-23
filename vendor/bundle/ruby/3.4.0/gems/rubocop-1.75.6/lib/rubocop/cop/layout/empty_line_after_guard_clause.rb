# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Enforces empty line after guard clause.
      #
      # This cop allows `# :nocov:` directive after guard clause because
      # SimpleCov excludes code from the coverage report by wrapping it in `# :nocov:`:
      #
      # [source,ruby]
      # ----
      # def foo
      #   # :nocov:
      #   return if condition
      #   # :nocov:
      #   bar
      # end
      # ----
      #
      # Refer to SimpleCov's documentation for more details:
      # https://github.com/simplecov-ruby/simplecov#ignoringskipping-code
      #
      # @example
      #
      #   # bad
      #   def foo
      #     return if need_return?
      #     bar
      #   end
      #
      #   # good
      #   def foo
      #     return if need_return?
      #
      #     bar
      #   end
      #
      #   # good
      #   def foo
      #     return if something?
      #     return if something_different?
      #
      #     bar
      #   end
      #
      #   # also good
      #   def foo
      #     if something?
      #       do_something
      #       return if need_return?
      #     end
      #   end
      class EmptyLineAfterGuardClause < Base
        include RangeHelp
        extend AutoCorrector
        extend Util

        MSG = 'Add empty line after guard clause.'
        END_OF_HEREDOC_LINE = 1
        SIMPLE_DIRECTIVE_COMMENT_PATTERN = /\A# *:nocov:\z/.freeze

        def on_if(node)
          return if correct_style?(node)
          return if multiple_statements_on_line?(node)

          if node.modifier_form? && (heredoc_node = last_heredoc_argument(node))
            if next_line_empty_or_allowed_directive_comment?(heredoc_line(node, heredoc_node))
              return
            end

            add_offense(heredoc_node.loc.heredoc_end) do |corrector|
              autocorrect(corrector, heredoc_node)
            end
          else
            return if next_line_empty_or_allowed_directive_comment?(node.last_line)

            add_offense(offense_location(node)) { |corrector| autocorrect(corrector, node) }
          end
        end

        private

        def autocorrect(corrector, node)
          node_range = if heredoc?(node)
                         range_by_whole_lines(node.loc.heredoc_body)
                       else
                         range_by_whole_lines(node.source_range)
                       end

          next_line = node_range.last_line + 1
          if next_line_allowed_directive_comment?(next_line)
            node_range = processed_source.comment_at_line(next_line)
          end

          corrector.insert_after(node_range, "\n")
        end

        def correct_style?(node)
          !contains_guard_clause?(node) ||
            next_line_rescue_or_ensure?(node) ||
            next_sibling_parent_empty_or_else?(node) ||
            next_sibling_empty_or_guard_clause?(node)
        end

        def contains_guard_clause?(node)
          node.if_branch&.guard_clause?
        end

        def next_line_empty_or_allowed_directive_comment?(line)
          return true if next_line_empty?(line)

          next_line = line + 1
          next_line_allowed_directive_comment?(next_line) && next_line_empty?(next_line)
        end

        def next_line_empty?(line)
          processed_source[line].blank?
        end

        def next_line_allowed_directive_comment?(line)
          return false unless (comment = processed_source.comment_at_line(line))

          DirectiveComment.new(comment).enabled? || simplecov_directive_comment?(comment)
        end

        def next_line_rescue_or_ensure?(node)
          parent = node.parent
          parent.nil? || parent.rescue_type? || parent.ensure_type?
        end

        def next_sibling_parent_empty_or_else?(node)
          next_sibling = node.right_sibling
          return true unless next_sibling.is_a?(AST::Node)

          parent = next_sibling.parent

          parent&.if_type? && parent.else?
        end

        def next_sibling_empty_or_guard_clause?(node)
          next_sibling = node.right_sibling
          return true if next_sibling.nil?

          next_sibling.if_type? && contains_guard_clause?(next_sibling)
        end

        def last_heredoc_argument(node)
          n = last_heredoc_argument_node(node)

          return n if heredoc?(n)
          return unless n.respond_to?(:arguments)

          n.arguments.each do |argument|
            node = last_heredoc_argument(argument)
            return node if node
          end

          last_heredoc_argument(n.receiver) if n.respond_to?(:receiver)
        end

        def last_heredoc_argument_node(node)
          return node unless node.respond_to?(:if_branch)

          if node.if_branch.and_type?
            node.if_branch.children.first
          elsif use_heredoc_in_condition?(node.condition)
            node.condition
          else
            node.if_branch.children.last
          end
        end

        def heredoc_line(node, heredoc_node)
          heredoc_body = heredoc_node.loc.heredoc_body
          num_of_heredoc_lines = heredoc_body.last_line - heredoc_body.first_line

          node.last_line + num_of_heredoc_lines + END_OF_HEREDOC_LINE
        end

        def heredoc?(node)
          node.respond_to?(:heredoc?) && node.heredoc?
        end

        def use_heredoc_in_condition?(condition)
          condition.descendants.any? do |descendant|
            descendant.respond_to?(:heredoc?) && descendant.heredoc?
          end
        end

        def offense_location(node)
          if node.loc?(:end)
            node.loc.end
          else
            node
          end
        end

        def multiple_statements_on_line?(node)
          parent = node.parent
          return false unless parent

          parent.begin_type? && same_line?(node, node.right_sibling)
        end

        # SimpleCov excludes code from the coverage report by wrapping it in `# :nocov:`:
        # https://github.com/simplecov-ruby/simplecov#ignoringskipping-code
        def simplecov_directive_comment?(comment)
          SIMPLE_DIRECTIVE_COMMENT_PATTERN.match?(comment.text)
        end
      end
    end
  end
end
