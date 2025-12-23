module SCSSLint
  # Ensures color literals are used only in variable declarations.
  class Linter::ColorVariable < Linter
    include LinterRegistry

    COLOR_FUNCTIONS = %w[rgb rgba hsl hsla].freeze

    def visit_script_color(node)
      return if in_variable_declaration?(node) ||
                in_map_declaration?(node) ||
                in_rgba_function_call?(node)

      # Source range sometimes includes closing parenthesis, so extract it
      color = source_from_range(node.source_range)[/(#?[a-z0-9]+)/i, 1]

      record_lint(node, color) if color?(color)
    end

    def visit_script_string(node)
      return if literal_string?(node)
      remove_quoted_strings(node.value)
        .scan(/(^|\s)(#[a-f0-9]+|[a-z]+)(?=\s|$)/i)
        .select { |_, word| color?(word) }
        .each   { |_, color| record_lint(node, color) }
    end

    def visit_script_funcall(node)
      if literal_color_function?(node)
        record_lint node, node.to_sass
      else
        yield
      end
    end

  private

    def record_lint(node, color)
      add_lint node, "Color literals like `#{color}` should only be used in " \
                     'variable declarations; they should be referred to via ' \
                     'variable everywhere else.'
    end

    def literal_string?(script_string)
      return unless script_string.respond_to?(:source_range) &&
        source_range = script_string.source_range

      # If original source starts with a quote character, it's a string, not a
      # color
      %w[' "].include?(source_from_range(source_range)[0])
    end

    def in_variable_declaration?(node)
      parent = node.node_parent
      parent.is_a?(Sass::Script::Tree::Literal) &&
        (parent.node_parent.is_a?(Sass::Tree::VariableNode) ||
         parent.node_parent.node_parent.is_a?(Sass::Tree::VariableNode))
    end

    def function_in_variable_declaration?(node)
      node.node_parent.is_a?(Sass::Tree::VariableNode) ||
        node.node_parent.node_parent.is_a?(Sass::Tree::VariableNode)
    end

    def in_rgba_function_call?(node)
      grandparent = node_ancestor(node, 2)

      grandparent.is_a?(Sass::Script::Tree::Funcall) &&
        grandparent.name == 'rgba'
    end

    def in_map_declaration?(node)
      node_ancestor(node, 2).is_a?(Sass::Script::Tree::MapLiteral)
    end

    def all_arguments_are_literals?(node)
      node.args.all? do |arg|
        arg.is_a?(Sass::Script::Tree::Literal)
      end
    end

    def color_function?(node)
      COLOR_FUNCTIONS.include?(node.name)
    end

    def literal_color_function?(node)
      color_function?(node) &&
        all_arguments_are_literals?(node) &&
        !function_in_variable_declaration?(node)
    end
  end
end
