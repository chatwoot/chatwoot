module SCSSLint
  # Checks for the use of double colons with pseudo elements.
  class Linter::PseudoElement < Linter
    include LinterRegistry

    # https://msdn.microsoft.com/en-us/library/windows/apps/hh767361.aspx
    # https://developer.mozilla.org/en-US/docs/Web/CSS/Mozilla_Extensions
    # http://tjvantoll.com/2013/04/15/list-of-pseudo-elements-to-style-form-controls/
    PSEUDO_ELEMENTS = File.open(File.join(SCSS_LINT_DATA, 'pseudo-elements.txt'))
                          .read
                          .split
                          .to_set

    def visit_pseudo(pseudo)
      if PSEUDO_ELEMENTS.include?(pseudo.name)
        return if pseudo.syntactic_type == :element
        add_lint(pseudo, 'Begin pseudo elements with double colons: `::`')
      else
        return if pseudo.syntactic_type != :element
        add_lint(pseudo, 'Begin pseudo classes with a single colon: `:`')
      end
    end
  end
end
