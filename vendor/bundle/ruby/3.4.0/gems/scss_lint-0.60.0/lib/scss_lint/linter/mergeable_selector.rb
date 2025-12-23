module SCSSLint
  # Checks for rule sets that can be merged with other rule sets.
  class Linter::MergeableSelector < Linter
    include LinterRegistry

    def check_node(node)
      node.children.each_with_object([]) do |child_node, seen_nodes|
        next unless child_node.is_a?(Sass::Tree::RuleNode)

        next if whitelist_contains(child_node)

        mergeable_node = find_mergeable_node(child_node, seen_nodes)
        seen_nodes << child_node
        next unless mergeable_node

        rule_text = node_rule(child_node).gsub(/(\r?\n)+/, ' ')

        add_lint child_node.line,
                 "Merge rule `#{rule_text}` with rule " \
                 "on line #{mergeable_node.line}"
      end

      yield # Continue linting children
    end

    alias visit_root check_node
    alias visit_rule check_node

  private

    def find_mergeable_node(node, seen_nodes)
      return if multiple_parent_references?(node)

      seen_nodes.find do |seen_node|
        equal?(node, seen_node) ||
          (config['force_nesting'] && nested?(node, seen_node))
      end
    end

    def multiple_parent_references?(rule_node)
      return unless rules = rule_node.parsed_rules

      # Iterate over each sequence counting all parent references
      total_parent_references = rules.members.inject(0) do |sum, seq|
        sum + seq.members.inject(0) do |ssum, simple_seq|
          next ssum unless simple_seq.respond_to?(:members)
          ssum + simple_seq.members.count do |member|
            member.is_a?(Sass::Selector::Parent)
          end
        end
      end

      total_parent_references > 1
    end

    def equal?(node1, node2)
      node_rule(node1) == node_rule(node2)
    end

    def nested?(node1, node2)
      return false unless single_rule?(node1) && single_rule?(node2)

      rule1 = node_rule(node1)
      rule2 = node_rule(node2)
      subrule?(rule1, rule2) || subrule?(rule2, rule1)
    end

    def node_rule(node)
      node.rule.join
    end

    def single_rule?(node)
      return unless node.parsed_rules
      node.parsed_rules.members.count == 1
    end

    def subrule?(rule1, rule2)
      rule1.to_s.start_with?("#{rule2} ", "#{rule2}.")
    end

    def whitelist_contains(node)
      if @whitelist.nil?
        @whitelist = config['whitelist'] || []
        @whitelist = [@whitelist] if @whitelist.is_a? String
      end

      @whitelist.include?(node_rule(node))
    end
  end
end
