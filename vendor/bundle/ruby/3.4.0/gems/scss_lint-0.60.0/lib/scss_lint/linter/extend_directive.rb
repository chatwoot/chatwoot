module SCSSLint
  # Checks that `@extend` is never used.
  class Linter::ExtendDirective < Linter
    include LinterRegistry

    def visit_extend(node)
      add_lint(node, 'Do not use the `@extend` directive (`@include` a `@mixin` ' \
                     'instead)')
    end
  end
end
