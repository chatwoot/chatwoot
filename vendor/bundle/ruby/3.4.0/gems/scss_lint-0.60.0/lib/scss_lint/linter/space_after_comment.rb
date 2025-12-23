module SCSSLint
  # Checks for a space after comment literals
  class Linter::SpaceAfterComment < Linter
    include LinterRegistry

    def visit_comment(node)
      source = source_from_range(node.source_range).strip
      check_method = "check_#{node.type}_comment"
      send(check_method, node, source)
    end

  private

    def check_silent_comment(node, source)
      source.split("\n").each_with_index do |line, index|
        next if config['allow_empty_comments'] && line.strip.length <= 2
        whitespace = whitespace_after_comment(line.lstrip, 2)
        check_for_space(node.line + index, whitespace)
      end
    end

    def check_normal_comment(node, source)
      whitespace = whitespace_after_comment(source, 2)
      check_for_space(node, whitespace)
    end

    def check_loud_comment(node, source)
      whitespace = whitespace_after_comment(source, 3)
      check_for_space(node, whitespace)
    end

    def check_for_no_spaces(node_or_line, whitespace)
      return if whitespace == 0
      add_lint(node_or_line, 'Comment literal should not be followed by any spaces')
    end

    def check_for_one_space(node_or_line, whitespace)
      return if whitespace == 1
      add_lint(node_or_line, 'Comment literal should be followed by one space')
    end

    def check_for_at_least_one_space(node_or_line, whitespace)
      return if whitespace >= 1
      add_lint(node_or_line, 'Comment literal should be followed by at least one space')
    end

    def check_for_space(node_or_line, spaces)
      case config['style']
      when 'one_space'
        check_for_one_space(node_or_line, spaces)
      when 'no_space'
        check_for_no_spaces(node_or_line, spaces)
      when 'at_least_one_space'
        check_for_at_least_one_space(node_or_line, spaces)
      end
    end

    def whitespace_after_comment(source, offset)
      whitespace = 0

      offset += 1 if source[offset] == '/' # Allow for triple-slash comments
      offset += 1 if source[offset] == '/' # Allow for quadruple-slash comments

      while [' ', "\t"].include? source[offset]
        whitespace += 1
        offset += 1
      end

      whitespace
    end
  end
end
