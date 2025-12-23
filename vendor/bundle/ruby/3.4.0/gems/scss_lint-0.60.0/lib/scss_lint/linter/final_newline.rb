module SCSSLint
  # Checks for final newlines at the end of a file.
  class Linter::FinalNewline < Linter
    include LinterRegistry

    def visit_root(_node)
      return if engine.lines.empty?

      ends_with_newline = engine.lines[-1][-1] == "\n"

      if config['present']
        unless ends_with_newline
          add_lint(engine.lines.count, 'Files should end with a trailing newline')
        end
      elsif ends_with_newline
        add_lint(engine.lines.count, 'Files should not end with a trailing newline')
      end

      yield
    end
  end
end
