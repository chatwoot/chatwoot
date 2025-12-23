# frozen_string_literal: true

module SCSSLint
  # Checks that selector sequences are split over multiple lines by comma.
  class Linter::SingleLinePerSelector < Linter
    include LinterRegistry

    MESSAGE = 'Each selector in a comma sequence should be on its own single line'.freeze

    def visit_comma_sequence(node)
      return unless node.members.count > 1

      check_comma_on_own_line(node)

      line_offset = 0
      node.members[1..-1].each do |sequence|
        line_offset += 1 if sequence_start_of_line?(sequence)
        check_multiline_sequence(node, sequence, line_offset)
        check_sequence_commas(node, sequence, line_offset)
      end
    end

    def visit_sequence(node)
      # Only execute if this is first or only sequence in a comma sequence. If
      # it is the only sequence, then it won't be in a comma sequence, which is
      # why we define a separate visit_* method specifically for this case.
      return if node.members.first == "\n"

      check_multiline_sequence(node, node, 0)
    end

  private

    def sequence_start_of_line?(sequence)
      sequence.members[0] == "\n"
    end

    def check_comma_on_own_line(node)
      return unless node.members[0].members[1] == "\n"
      add_lint(node, MESSAGE)
    end

    # Checks if an individual sequence is split over multiple lines
    def check_multiline_sequence(node, sequence, index)
      return unless sequence.members.size > 1
      return unless sequence.members[2..-1].any? { |member| member == "\n" }

      add_lint(node.line + index, MESSAGE)
    end

    def check_sequence_commas(node, sequence, index)
      if !sequence_start_of_line?(sequence)
        # Next sequence doesn't reside on its own line
        add_lint(node.line + index, MESSAGE)
      elsif sequence.members[1] == "\n"
        # Comma is on its own line
        add_lint(node.line + index, MESSAGE)
      end
    end
  end
end
