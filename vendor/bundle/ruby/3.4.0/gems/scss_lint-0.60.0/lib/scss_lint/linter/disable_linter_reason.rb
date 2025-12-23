module SCSSLint
  # Checks for "reason" comments above linter-disabling comments.
  class Linter::DisableLinterReason < Linter
    include LinterRegistry

    def visit_comment(node)
      # No lint if the first line of the comment is not a command (because then
      # either this comment has no commands, or the first line serves as a the
      # reason for a command on a later line).
      if comment_lines(node).first.match?(COMMAND_REGEX)
        visit_command_comment(node)
      else
        @previous_comment = node
      end
    end

    def visit_command_comment(node)
      if @previous_comment.nil?
        report_lint(node)
        return
      end

      # Not a "disable linter reason" if the last line of the previous comment is a command.
      if comment_lines(@previous_comment).last.match?(COMMAND_REGEX)
        report_lint(node)
        return
      end

      # No lint if the last line of the previous comment is on the previous line.
      if @previous_comment.source_range.end_pos.line == node.source_range.end_pos.line - 1
        return
      end

      # The "reason" comment doesn't have to be on the previous line, as long as it is exactly
      # the previous node.
      if previous_node(node) == @previous_comment
        return
      end

      report_lint(node)
    end

  private

    COMMAND_REGEX = %r{
      (/|\*)\s* # Comment start marker
      scss-lint:
      (?<action>disable)\s+
      (?<linters>.*?)
      \s*(?:\*/|\n) # Comment end marker or end of line
    }x.freeze

    def comment_lines(node)
      node.value.join.split("\n")
    end

    def report_lint(node)
      add_lint(node,
               'scss-lint:disable control comments should be preceded by a ' \
               'comment explaining why the linters need to be disabled.')
    end
  end
end
