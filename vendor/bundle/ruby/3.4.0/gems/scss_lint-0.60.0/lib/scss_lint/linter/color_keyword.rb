module SCSSLint
  # Checks for uses of a color keyword instead of the preferred hexadecimal
  # form.
  class Linter::ColorKeyword < Linter
    include LinterRegistry

    FUNCTIONS_ALLOWING_COLOR_KEYWORD_ARGS = %w[
      map-get
      map-has-key
      map-remove
    ].to_set

    def visit_script_color(node)
      word = source_from_range(node.source_range)[/([a-z]+)/i, 1]
      add_color_lint(node, word) if color_keyword?(word)
    end

    def visit_script_string(node)
      return unless node.type == :identifier

      remove_quoted_strings(node.value).scan(/(^|\s)([a-z]+)(?=\s|$)/i) do |_, word|
        add_color_lint(node, word) if color_keyword?(word)
      end
    end

  private

    def add_color_lint(node, original)
      return if in_map?(node) || in_allowed_function_call?(node)

      hex_form = Sass::Script::Value::Color.new(color_keyword_to_code(original)).tap do |color|
        color.options = {} # `inspect` requires options to be set
      end.inspect

      add_lint(node,
               "Color `#{original}` should be written in hexadecimal form " \
               "as `#{hex_form}`")
    end

    def in_map?(node)
      node_ancestor(node, 2).is_a?(Sass::Script::Tree::MapLiteral)
    end

    def in_allowed_function_call?(node)
      (funcall = node_ancestor(node, 2)).is_a?(Sass::Script::Tree::Funcall) &&
        FUNCTIONS_ALLOWING_COLOR_KEYWORD_ARGS.include?(funcall.name)
    end
  end
end
