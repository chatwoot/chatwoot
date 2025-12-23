module SCSSLint
  # Checks for a trailing semicolon on statements within rule sets.
  class Linter::TrailingSemicolon < Linter
    include LinterRegistry

    def visit_extend(node)
      check_semicolon(node)
    end

    def visit_variable(node)
      # If the variable is using `!default` or `!global` (e.g. `$foo: bar
      # !default;`) then `node.expr` will give us the source range just for the
      # value (e.g. `bar`). In these cases, we want to use the source range of
      # `node`, which will give us most of the entire line (e.g. `foo: bar
      # !default`.
      return check_semicolon(node) if node.global || node.guarded

      # If the variable is a multi-line ListLiteral or MapLiteral, then
      # `node.expr` will give us everything except the last right paren, and
      # the semicolon if it exists. In these cases, use the source range of
      # `node` as above.
      if node.expr.is_a?(Sass::Script::Tree::ListLiteral) ||
          node.expr.is_a?(Sass::Script::Tree::MapLiteral)
        return check_semicolon(node)
      end

      check_semicolon(node.expr)
    end

    def visit_prop(node)
      if node.children.any? { |n| n.is_a?(Sass::Tree::PropNode) }
        yield # Continue checking children
      else
        check_semicolon(node)
      end
    end

    def visit_mixin(node)
      if node.children.any?
        yield # Continue checking children
      else
        check_semicolon(node)
      end
    end

    def visit_import(node)
      # Ignore all but the last import for comma-separated @imports
      return if source_from_range(node.source_range).match?(/,\s*$/)
      check_semicolon(node)
    end

  private

    def check_semicolon(node)
      if has_space_before_semicolon?(node)
        line = node.source_range.start_pos.line
        add_lint line,
                 'Declaration should not have a space before ' \
                 'the terminating semicolon'
      elsif !ends_with_semicolon?(node)
        line = node.source_range.start_pos.line
        add_lint line, 'Declaration should be terminated by a semicolon'
      elsif ends_with_multiple_semicolons?(node)
        line = node.source_range.start_pos.line
        add_lint line, 'Declaration should be terminated by a single semicolon'
      end
    end

    # Checks that the node is ended by a semicolon (with no whitespace)
    def ends_with_semicolon?(node)
      semicolon_after_parenthesis?(node) ||
        # Otherwise just check for a semicolon
        source_from_range(node.source_range) =~ /;(\s*})?$/
    end

    # Special case: Sass doesn't include the semicolon after an expression
    # in the source range it reports, so we need a helper to check after the
    # reported range.
    def semicolon_after_parenthesis?(node)
      last_char = character_at(node.source_range.end_pos)
      char_after = character_at(node.source_range.end_pos, 1)
      (last_char == ')' && char_after == ';') ||
        ([last_char, char_after].include?("\n") &&
         engine.lines[node.source_range.end_pos.line] =~ /\);(\s*})?$/)
    end

    def ends_with_multiple_semicolons?(node)
      # Look one character past the end to see if there's another semicolon
      character_at(node.source_range.end_pos) == ';' &&
        character_at(node.source_range.end_pos, 1) == ';'
    end

    def has_space_before_semicolon?(node)
      source_from_range(node.source_range) =~ /\s;(\s*})?$/
    end
  end
end
