module SCSSLint
  # Checks that all properties in a rule set are on their own distinct lines.
  class Linter::SingleLinePerProperty < Linter
    include LinterRegistry

    def visit_rule(node)
      yield # Continue linting children

      single_line = single_line_rule_set?(node)
      return if single_line && config['allow_single_line_rule_sets']

      properties = node.children.select { |child| child.is_a?(Sass::Tree::PropNode) }
      return unless properties.any?

      # Special case: if single line rule sets aren't allowed, we want to report
      # when the first property isn't on a separate line from the selector
      if single_line && !config['allow_single_line_rule_sets']
        add_lint(properties.first,
                 "Property '#{properties.first.name.join}' should be placed " \
                 'on separate line from selector')
      end

      check_adjacent_properties(properties)
    end

  private

    # Return whether this rule set occupies a single line.
    #
    # Note that this allows:
    #   a,
    #   b,
    #   i { margin: 0; padding: 0; }
    #
    # and:
    #
    #   p { margin: 0; padding: 0; }
    #
    # In other words, the line of the opening curly brace is the line that the
    # rule set is considered to occupy.
    def single_line_rule_set?(rule)
      rule.children.all? { |child| child.line == rule.source_range.end_pos.line }
    end

    def first_property_not_on_own_line?(rule, properties)
      properties.any? && properties.first.line == rule.line
    end

    # Compare each property against the next property to see if they are on
    # the same line.
    #
    # @param properties [Array<Sass::Tree::PropNode>]
    def check_adjacent_properties(properties)
      properties[0..-2].zip(properties[1..-1]).each do |first, second|
        next unless first.line == second.line

        add_lint(second, "Property '#{second.name.join}' should be placed on own line")
      end
    end
  end
end
