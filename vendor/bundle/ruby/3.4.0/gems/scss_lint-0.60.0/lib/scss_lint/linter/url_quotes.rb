module SCSSLint
  # Checks for quotes in URLs.
  class Linter::UrlQuotes < Linter
    include LinterRegistry

    def visit_prop(node)
      case node.value.first
      when Sass::Script::Tree::Literal
        check(node, node.value.first.value.to_s)
      when Sass::Script::Tree::ListLiteral
        node.value.first
            .children
            .select { |child| child.is_a?(Sass::Script::Tree::Literal) }
            .each { |child| check(node, child.value.to_s) }
      end

      yield
    end

  private

    def check(node, string)
      return unless string.match?(/^\s*url\(\s*[^"']/)
      return if string.match?(/^\s*url\(\s*data:/) # Ignore data URIs

      add_lint(node, 'URLs should be enclosed in quotes')
    end
  end
end
