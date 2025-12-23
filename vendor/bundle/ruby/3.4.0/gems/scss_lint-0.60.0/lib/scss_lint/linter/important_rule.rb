module SCSSLint
  # Reports the use of !important in properties.
  class Linter::ImportantRule < Linter
    include LinterRegistry

    def visit_prop(node)
      return unless source_from_range(node.source_range).include?('!important')

      add_lint(node, '!important should not be used')
    end
  end
end
