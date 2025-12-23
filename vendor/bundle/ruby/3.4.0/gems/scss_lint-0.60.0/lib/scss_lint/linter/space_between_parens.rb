module SCSSLint
  # Checks for the presence of spaces between parentheses.
  class Linter::SpaceBetweenParens < Linter
    include LinterRegistry

    def check_node(node)
      check(node, source_from_range(node.source_range))
      yield
    end

    alias visit_atroot check_node
    alias visit_cssimport check_node
    alias visit_function check_node
    alias visit_media check_node
    alias visit_mixindef check_node
    alias visit_mixin check_node
    alias visit_script_funcall check_node

    def feel_for_parens_and_check_node(node)
      source = feel_for_enclosing_parens(node)
      check(node, source)
      yield
    end

    alias visit_script_listliteral feel_for_parens_and_check_node
    alias visit_script_mapliteral feel_for_parens_and_check_node
    alias visit_script_operation feel_for_parens_and_check_node
    alias visit_script_string feel_for_parens_and_check_node

  private

    TRAILING_WHITESPACE = /\s*$/.freeze

    def check(node, source) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      @spaces = config['spaces']
      source = trim_right_paren(source)
      return if source.count('(') != source.count(')')
      source.scan(/
          \(
          (?<left>\s*)
          (?<contents>.*)
          (?<right>\s*)
          \)
      /x) do |left, contents, right|
        right = contents.match(TRAILING_WHITESPACE)[0] + right
        contents.gsub(TRAILING_WHITESPACE, '')

        # We don't lint on multiline parenthetical source.
        break if (left + contents + right).include? "\n"

        if contents.empty?
          # If we're looking at empty parens (like `()`, `( )`, `(  )`, etc.),
          # only report a possible lint on the left side.
          right = ' ' * @spaces
        end

        if left != ' ' * @spaces
          message = "#{expected_spaces} after `(` instead of `#{left}`"
          add_lint(node, message)
        end

        if right != ' ' * @spaces
          message = "#{expected_spaces} before `)` instead of `#{right}`"
          add_lint(node, message)
        end
      end
    end

    # An expression enclosed in parens will include or not include each paren, depending
    # on whitespace. Here we feel out for enclosing parens, and return them as the new
    # source for the node.
    def feel_for_enclosing_parens(node) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      range = node.source_range
      original_source = source_from_range(range)
      left_offset = -1
      right_offset = 0

      if original_source[-1] != ')'
        right_offset += 1 while character_at(range.end_pos, right_offset) =~ /\s/

        return original_source if character_at(range.end_pos, right_offset) != ')'
      end

      # At this point, we know that we're wrapped on the right by a ')'.
      # Are we wrapped on the left by a '('?
      left_offset -= 1 while character_at(range.start_pos, left_offset) =~ /\s/
      return original_source if character_at(range.start_pos, left_offset) != '('

      # At this point, we know we're wrapped on both sides by parens. However,
      # those parens may be part of a parent function call. We don't care about
      # such parens. This depends on whether the preceding character is part of
      # a function name.
      return original_source if character_at(range.start_pos, left_offset - 1).match?(/[A-Za-z0-9_]/)

      range.start_pos.offset += left_offset
      range.end_pos.offset += right_offset
      source_from_range(range)
    end

    # An unrelated right paren will sneak into the source of a node if there is no
    # whitespace between the node and the right paren.
    def trim_right_paren(source)
      source.count(')') == source.count('(') + 1 ? source[0..-2] : source
    end

    def expected_spaces
      "Expected #{pluralize(@spaces, 'space')}"
    end
  end
end
