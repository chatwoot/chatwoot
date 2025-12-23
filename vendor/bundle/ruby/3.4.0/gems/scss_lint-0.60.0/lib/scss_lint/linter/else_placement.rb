module SCSSLint
  # Checks where `@else` and `@else if` directives are placed with respect to
  # the previous curly brace.
  class Linter::ElsePlacement < Linter
    include LinterRegistry

    def visit_if(node)
      visit_else(node, node.else) if node.else
      yield # Lint nested @if statements
      visit(node.else) if node.else
    end

    def visit_else(if_node, else_node)
      # Check each @else branch if there are multiple `@else if`s
      visit_else(else_node, else_node.else) if else_node.else

      # Skip @else statements on the same line as the previous @if, since we
      # don't care about placement in that case
      return if if_node.line == else_node.line

      spaces = 0
      while (char = character_at(else_node.source_range.start_pos, - (spaces + 1)))
        if char == '}'
          curly_on_same_line = true
          break
        end
        spaces += 1
      end

      check_placement(else_node, curly_on_same_line)
    end

  private

    def check_placement(else_node, curly_on_same_line)
      if same_line_preferred?
        unless curly_on_same_line
          add_lint(else_node,
                   '`@else` should be placed on same line as previous curly brace')
        end
      elsif curly_on_same_line
        add_lint(else_node, '`@else` should be placed on its own line')
      end
    end

    def same_line_preferred?
      config['style'] == 'same_line'
    end
  end
end
