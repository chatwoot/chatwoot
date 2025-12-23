module SCSSLint
  # Checks for leftover `@debug` statements.
  class Linter::DebugStatement < Linter
    include LinterRegistry

    def visit_debug(node)
      add_lint(node, 'Remove `@debug` line')
    end
  end
end
