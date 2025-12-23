module Sass
  module Tree
    # A dynamic node representing an `@at-root` directive.
    #
    # An `@at-root` directive with a selector is converted to an \{AtRootNode}
    # containing a \{RuleNode} at parse time.
    #
    # @see Sass::Tree
    class AtRootNode < Node
      # The query for this node (e.g. `(without: media)`),
      # interspersed with {Sass::Script::Tree::Node}s representing
      # `#{}`-interpolation. Any adjacent strings will be merged
      # together.
      #
      # This will be nil if the directive didn't have a query. In this
      # case, {#resolved\_type} will automatically be set to
      # `:without` and {#resolved\_rule} will automatically be set to `["rule"]`.
      #
      # @return [Array<String, Sass::Script::Tree::Node>]
      attr_accessor :query

      # The resolved type of this directive. `:with` or `:without`.
      #
      # @return [Symbol]
      attr_accessor :resolved_type

      # The resolved value of this directive -- a list of directives
      # to either include or exclude.
      #
      # @return [Array<String>]
      attr_accessor :resolved_value

      # The number of additional tabs that the contents of this node
      # should be indented.
      #
      # @return [Number]
      attr_accessor :tabs

      # Whether the last child of this node should be considered the
      # end of a group.
      #
      # @return [Boolean]
      attr_accessor :group_end

      def initialize(query = nil)
        super()
        @query = Sass::Util.strip_string_array(Sass::Util.merge_adjacent_strings(query)) if query
        @tabs = 0
      end

      # Returns whether or not the given directive is excluded by this
      # node. `directive` may be "rule", which indicates whether
      # normal CSS rules should be excluded.
      #
      # @param directive [String]
      # @return [Boolean]
      def exclude?(directive)
        if resolved_type == :with
          return false if resolved_value.include?('all')
          !resolved_value.include?(directive)
        else # resolved_type == :without
          return true if resolved_value.include?('all')
          resolved_value.include?(directive)
        end
      end

      # Returns whether the given node is excluded by this node.
      #
      # @param node [Sass::Tree::Node]
      # @return [Boolean]
      def exclude_node?(node)
        return exclude?(node.name.gsub(/^@/, '')) if node.is_a?(Sass::Tree::DirectiveNode)
        return exclude?('keyframes') if node.is_a?(Sass::Tree::KeyframeRuleNode)
        exclude?('rule') && node.is_a?(Sass::Tree::RuleNode)
      end

      # @see Node#bubbles?
      def bubbles?
        true
      end
    end
  end
end
