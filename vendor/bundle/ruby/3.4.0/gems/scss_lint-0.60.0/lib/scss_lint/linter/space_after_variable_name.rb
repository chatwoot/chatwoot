module SCSSLint
  # Checks for spaces following the name of a variable and before the colon
  # separating the variables's name from its value.
  class Linter::SpaceAfterVariableName < Linter
    include LinterRegistry

    def visit_variable(node)
      return unless spaces_before_colon?(node)
      add_lint(node, 'Variable names should be followed immediately by a colon')
    end

  private

    def spaces_before_colon?(node)
      source_from_range(node.source_range) =~ /\A[^:]+\s+:/
    end
  end
end
