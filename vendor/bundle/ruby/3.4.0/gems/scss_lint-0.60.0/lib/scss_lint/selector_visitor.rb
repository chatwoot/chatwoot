module SCSSLint
  # Provides functionality for conveniently visiting a Selector sequence.
  module SelectorVisitor
    def visit_selector(node)
      visit_selector_node(node)
    end

  private

    def visit_selector_node(node)
      method = "visit_#{selector_node_name(node)}"
      send(method, node) if respond_to?(method, true)

      visit_members(node) if node.is_a?(Sass::Selector::AbstractSequence)
    end

    def visit_members(sequence)
      sequence.members
              .reject { |member| member.is_a?(String) } # Skip newlines in multi-line comma seqs
              .each do |member|
        visit_selector(member)
      end
    end

    # The class name of a node, in snake_case form, e.g.
    # `Sass::Selector::SimpleSequence` -> `simple_sequence`.
    #
    # The name is memoized as a class variable on the node itself.
    def selector_node_name(node)
      if node.class.class_variable_defined?(:@@snake_case_name)
        return node.class.class_variable_get(:@@snake_case_name)
      end

      rindex = node.class.name.rindex('::')
      name = node.class.name[(rindex + 2)..-1]
      name.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      name.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      name.downcase!
      node.class.class_variable_set(:@@snake_case_name, name)
    end
  end
end
