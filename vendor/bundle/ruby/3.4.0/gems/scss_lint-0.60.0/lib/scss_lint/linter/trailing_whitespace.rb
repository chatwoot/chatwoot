module SCSSLint
  # Checks for trailing whitespace on a line.
  class Linter::TrailingWhitespace < Linter
    include LinterRegistry

    def visit_root(_node)
      engine.lines.each_with_index do |line, index|
        next unless line.match?(/[ \t]+$/)

        add_lint(index + 1, 'Line contains trailing whitespace')
      end
      yield
    end
  end
end
