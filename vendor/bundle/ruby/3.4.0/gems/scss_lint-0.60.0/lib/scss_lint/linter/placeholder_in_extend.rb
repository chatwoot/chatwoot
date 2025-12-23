module SCSSLint
  # Checks that `@extend` is always used with a placeholder selector.
  class Linter::PlaceholderInExtend < Linter
    include LinterRegistry

    def visit_extend(node)
      # Ignore if it cannot be statically determined that this selector is a
      # placeholder since its prefix is dynamically generated
      return if node.selector.first.is_a?(Sass::Script::Tree::Node)

      # The array returned by the parser is a bit awkward in that it splits on
      # every word boundary (so %placeholder becomes ['%', 'placeholder']).
      selector = node.selector.join

      if selector.include?(',')
        add_lint(node, 'Avoid comma sequences in `@extend` directives; ' \
                       'prefer single placeholder selectors (e.g. `%some-placeholder`)')
      elsif !selector.start_with?('%')
        add_lint(node, 'Prefer using placeholder selectors (e.g. ' \
                       '%some-placeholder) with @extend')
      end
    end
  end
end
