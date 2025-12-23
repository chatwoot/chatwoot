module SCSSLint
  # Checks for spaces following the colon that separates a variable's name from
  # its value.
  class Linter::SpaceAfterVariableColon < Linter
    include LinterRegistry

    def visit_variable(node)
      whitespace = whitespace_after_colon(node)

      case config['style']
      when 'no_space'
        check_for_no_spaces(node, whitespace)
      when 'one_space'
        check_for_one_space(node, whitespace)
      when 'at_least_one_space'
        check_for_at_least_one_space(node, whitespace)
      when 'one_space_or_newline'
        check_for_one_space_or_newline(node, whitespace)
      end
    end

  private

    def check_for_no_spaces(node, whitespace)
      return if whitespace == []
      add_lint(node, 'Colon after variable should not be followed by any spaces')
    end

    def check_for_one_space(node, whitespace)
      return if whitespace == [' ']
      add_lint(node, 'Colon after variable should be followed by one space')
    end

    def check_for_at_least_one_space(node, whitespace)
      return if whitespace.uniq == [' ']
      add_lint(node, 'Colon after variable should be followed by at least one space')
    end

    def check_for_one_space_or_newline(node, whitespace)
      return if [[' '], ["\n"]].include?(whitespace)
      return if whitespace[0] == "\n" && whitespace[1..-1].uniq == [' ']
      add_lint(node, 'Colon after variable should be followed by one space or a newline')
    end

    def whitespace_after_colon(node)
      whitespace = []
      offset = 0
      start_pos = node.source_range.start_pos

      # Find the colon after the variable name
      offset = offset_to(start_pos, ':', offset) + 1

      # Count spaces after the colon
      while [' ', "\t", "\n"].include?(character_at(start_pos, offset))
        whitespace << character_at(start_pos, offset)
        offset += 1
      end

      whitespace
    end
  end
end
