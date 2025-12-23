module SCSSLint
  # Checks the type of quotes used in string literals.
  class Linter::StringQuotes < Linter
    include LinterRegistry

    def visit_script_stringinterpolation(node)
      # We can't statically determine what the resultant string looks like when
      # string interpolation is used, e.g. "one #{$var} three" could be a very
      # different string depending on $var = `'" + "'` or $var = `two`.
      #
      # Thus we manually skip the substrings in the string interpolation and
      # visit the expressions in the interpolation itself.
      node.children
          .reject { |child| child.is_a?(Sass::Script::Tree::Literal) }
          .each { |child| visit(child) }
    end

    def visit_script_string(node)
      check_quotes(node, source_from_range(node.source_range))
    end

    def visit_import(node)
      # `@import` source range conveniently includes only the quoted string
      check_quotes(node, source_from_range(node.source_range))
    end

  private

    def check_quotes(node, source)
      source = source.strip
      string = extract_string_without_quotes(source)
      return unless string

      case source[0]
      when '"'
        check_double_quotes(node, string)
      when "'"
        check_single_quotes(node, string)
      end
    end

    STRING_WITHOUT_QUOTES_REGEX = %r{
      \A
      ["'](.*)["']    # Extract text between quotes
      \s*\)?\s*;?\s*  # Sometimes the Sass parser includes a trailing ) or ;
      (//.*)?         # Exclude any trailing comments that might have snuck in
      \z
    }x.freeze

    def extract_string_without_quotes(source)
      return unless match = STRING_WITHOUT_QUOTES_REGEX.match(source)
      match[1]
    end

    def check_double_quotes(node, string)
      if config['style'] == 'single_quotes'
        add_lint(node, 'Prefer single quoted strings') if string !~ /'/
      elsif string =~ /(?<! \\) \\"/x && string !~ /'/
        add_lint(node, 'Use single-quoted strings when writing double ' \
                       'quotes to avoid having to escape the double quotes')
      end
    end

    def check_single_quotes(node, string)
      if config['style'] == 'single_quotes'
        if string =~ /(?<! \\) \\'/x && string !~ /"/
          add_lint(node, 'Use double-quoted strings when writing single ' \
                         'quotes to avoid having to escape the single quotes')
        elsif string.match?(/(?<! \\) \\"/x)
          add_lint(node, "Don't escape double quotes in single-quoted strings")
        end
      elsif string !~ /"/
        add_lint(node, 'Prefer double-quoted strings')
      end
    end
  end
end
