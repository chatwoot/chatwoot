module SCSSLint
  # Checks for rule sets nested deeper than a specified maximum depth.
  class Linter::NestingDepth < Linter
    include LinterRegistry

    IGNORED_SELECTORS = [Sass::Selector::Parent, Sass::Selector::Pseudo].freeze

    def visit_root(_node)
      @max_depth = config['max_depth']
      @depth = 1
      yield # Continue linting children
    end

    def visit_rule(node)
      return yield if ignore_selectors?(node)

      if @depth > @max_depth
        add_lint node, "Nesting should be no greater than #{@max_depth}, " \
                       "but was #{@depth}"
      else
        # Only continue if we didn't exceed the max depth already (this makes
        # the lint less noisy)
        @depth += 1
        yield # Continue linting children
        @depth -= 1
      end
    end

  private

    def ignore_selectors?(node)
      return unless config['ignore_parent_selectors']
      return unless node.parsed_rules

      simple_selectors(node.parsed_rules).all? do |selector|
        IGNORED_SELECTORS.include?(selector.class)
      end
    end

    def simple_selectors(node)
      node.members.flat_map(&:members).reject do |simple_sequence|
        simple_sequence.is_a?(String)
      end.flat_map(&:members)
    end
  end
end
