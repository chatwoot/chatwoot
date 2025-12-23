module SCSSLint
  # Checks for the use of an ID selector.
  class Linter::IdSelector < Linter
    include LinterRegistry

    def visit_id(id)
      add_lint(id, 'Avoid using id selectors')
    end
  end
end
