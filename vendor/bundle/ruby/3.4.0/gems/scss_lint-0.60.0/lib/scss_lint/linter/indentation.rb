module SCSSLint
  # Checks for consistent indentation of nested declarations and rule sets.
  class Linter::Indentation < Linter # rubocop:disable ClassLength
    include LinterRegistry

    def visit_root(_node)
      @indent_width = config['width'].to_i
      @indent_character = config['character'] || 'space'
      if @indent_character == 'tab'
        @other_character = ' '
        @other_character_name = 'space'
      else
        @other_character = "\t"
        @other_character_name = 'tab'
      end
      @allow_non_nested_indentation = config['allow_non_nested_indentation']
      @indent = 0
      @indentations = {}
      yield
    end

    def check_and_visit_children(node)
      # Don't continue checking children as the moment a parent's indentation is
      # off it's likely the children will be as will. We don't display the child
      # indentation problems as that would likely make the lint too noisy.
      return if check_indentation(node)

      @indent += @indent_width
      yield
      @indent -= @indent_width
    end

    def check_indentation(node)
      return unless node.line

      # Ignore the case where the node is on the same line as its previous
      # sibling or its parent, as indentation isn't possible
      return if nodes_on_same_line?(previous_node(node), node)

      check_indent_width(node)
    end

    def check_indent_width(node)
      actual_indent = node_indent(node)

      if actual_indent.include?(@other_character)
        add_lint(node.line,
                 "Line should be indented with #{@indent_character}s, " \
                 "not #{@other_character_name}s")
        return true
      end

      if @allow_non_nested_indentation
        check_arbitrary_indent(node, actual_indent.length)
      else
        check_regular_indent(node, actual_indent.length)
      end
    end

    # Deal with `else` statements, which require special care since they are
    # considered children of `if` statements.
    def visit_if(node)
      check_indentation(node)

      if @allow_non_nested_indentation
        yield # Continue linting else statement
      elsif node.else
        visit(node.else)
      end
    end

    # Need to define this explicitly since @at-root directives can contain
    # inline selectors which produces the same parse tree as if the selector was
    # nested within it. For example:
    #
    #   @at-root {
    #     .something {
    #       ...
    #     }
    #   }
    #
    # ...and...
    #
    #   @at-root .something {
    #     ...
    #   }
    #
    # ...produce the same parse tree, but result in different indentation
    # levels.
    def visit_atroot(node, &block)
      if at_root_contains_inline_selector?(node)
        return if check_indentation(node)
        yield
      else
        check_and_visit_children(node, &block)
      end
    end

    def visit_import(node)
      previous_node(node)
      return unless engine.lines[node.line - 1].match?(/@import/)
      check_indentation(node)
    end

    # Define node types that increase indentation level
    alias visit_directive check_and_visit_children
    alias visit_each check_and_visit_children
    alias visit_for check_and_visit_children
    alias visit_function check_and_visit_children
    alias visit_media check_and_visit_children
    alias visit_mixin check_and_visit_children
    alias visit_mixindef check_and_visit_children
    alias visit_prop check_and_visit_children
    alias visit_rule check_and_visit_children
    alias visit_supports check_and_visit_children
    alias visit_while check_and_visit_children

    # Define node types to check indentation of (notice comments are left out)
    alias visit_charset check_indentation
    alias visit_content check_indentation
    alias visit_cssimport check_indentation
    alias visit_extend check_indentation
    alias visit_return check_indentation
    alias visit_variable check_indentation
    alias visit_warn check_indentation

  private

    def nodes_on_same_line?(node1, node2)
      return unless node1

      node1.line == node2.line ||
        (node1.source_range && node1.source_range.end_pos.line == node2.line)
    end

    def at_root_contains_inline_selector?(node)
      return unless node.children.any?
      return unless first_child_source = node.children.first.source_range

      same_position?(node.source_range.end_pos, first_child_source.start_pos)
    end

    def check_regular_indent(node, actual_indent)
      return if actual_indent == @indent

      add_lint(node.line, lint_message(@indent, actual_indent))
      true
    end

    def check_arbitrary_indent(node, actual_indent)
      return if check_root_ruleset_indent(node, actual_indent)

      # Allow any root-level node (i.e. one that would normally have an indent
      # of zero) to have an arbitrary amount of indent
      return if @indent == 0

      return if one_shift_greater_than_parent?(node, actual_indent)
      parent_indent = node_indent(node_indent_parent(node)).length
      expected_indent = parent_indent + @indent_width
      add_lint(node.line, lint_message(expected_indent, actual_indent))
      true
    end

    # Allow rulesets to be indented any amount when the indent is zero, as long
    # as it's a multiple of the indent width
    def check_root_ruleset_indent(node, actual_indent)
      # Whether node is a ruleset not nested within any other ruleset.
      if @indent == 0 && node.is_a?(Sass::Tree::RuleNode)
        unless actual_indent % @indent_width == 0
          add_lint(node.line, lint_message("a multiple of #{@indent_width}", actual_indent))
          return true
        end
      end

      false
    end

    # Returns whether node is indented exactly one indent width greater than its
    # parent.
    #
    # @param node [Sass::Tree::Node]
    # @return [true,false]
    def one_shift_greater_than_parent?(node, actual_indent)
      parent_indent = node_indent(node_indent_parent(node)).length
      expected_indent = parent_indent + @indent_width
      expected_indent == actual_indent
    end

    # Return indentation of a node.
    #
    # @param node [Sass::Tree::Node]
    # @return [Integer]
    def node_indent(node)
      @indentations[node] ||= engine.lines[node.line - 1][/^(\s*)/]
    end

    def node_indent_parent(node)
      if else_node?(node)
        while node.node_parent.is_a?(Sass::Tree::IfNode) &&
              node.node_parent.else == node
          node = node.node_parent
        end
      end

      node.node_parent
    end

    def lint_message(expected, actual)
      "Line should be indented #{expected} #{@indent_character}s, but was " \
      "indented #{actual} #{@indent_character}s"
    end
  end
end
