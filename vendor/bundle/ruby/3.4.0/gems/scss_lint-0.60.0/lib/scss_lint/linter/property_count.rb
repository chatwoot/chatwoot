module SCSSLint
  # Checks that the number of properties in a rule set is under a defined limit.
  class Linter::PropertyCount < Linter
    include LinterRegistry

    def visit_root(_node)
      @property_count = {} # Lookup table of counts for rule sets
      @max = config['max_properties']
      yield # Continue linting children
    end

    def visit_rule(node)
      count = property_count(node)

      if count > @max
        add_lint node,
                 "Rule set contains (#{count}/#{@max}) properties" \
                 "#{' (including properties in nested rule sets)' if config['include_nested']}"

        # Don't lint nested rule sets as we already have them in the count
        return if config['include_nested']
      end

      yield # Lint nested rule sets
    end

  private

    def property_count(rule_node)
      @property_count[rule_node] ||=
        begin
          count = rule_node.children.count { |node| node.is_a?(Sass::Tree::PropNode) }

          if config['include_nested']
            count += rule_node.children.inject(0) do |sum, node|
              node.is_a?(Sass::Tree::RuleNode) ? sum + property_count(node) : sum
            end
          end

          count
        end
    end
  end
end
