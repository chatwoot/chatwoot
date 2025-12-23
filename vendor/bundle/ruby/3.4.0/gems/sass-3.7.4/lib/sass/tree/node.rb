module Sass
  # A namespace for nodes in the Sass parse tree.
  #
  # The Sass parse tree has three states: dynamic, static Sass, and static CSS.
  #
  # When it's first parsed, a Sass document is in the dynamic state.
  # It has nodes for mixin definitions and `@for` loops and so forth,
  # in addition to nodes for CSS rules and properties.
  # Nodes that only appear in this state are called **dynamic nodes**.
  #
  # {Tree::Visitors::Perform} creates a static Sass tree, which is
  # different. It still has nodes for CSS rules and properties but it
  # doesn't have any dynamic-generation-related nodes. The nodes in
  # this state are in a similar structure to the Sass document: rules
  # and properties are nested beneath one another, although the
  # {Tree::RuleNode} selectors are already in their final state. Nodes
  # that can be in this state or in the dynamic state are called
  # **static nodes**; nodes that can only be in this state are called
  # **solely static nodes**.
  #
  # {Tree::Visitors::Cssize} is then used to create a static CSS tree.
  # This is like a static Sass tree,
  # but the structure exactly mirrors that of the generated CSS.
  # Rules and properties can't be nested beneath one another in this state.
  #
  # Finally, {Tree::Visitors::ToCss} can be called on a static CSS tree
  # to get the actual CSS code as a string.
  module Tree
    # The abstract superclass of all parse-tree nodes.
    class Node
      include Enumerable

      def self.inherited(base)
        node_name = base.name.gsub(/.*::(.*?)Node$/, '\\1').downcase
        base.instance_eval <<-METHODS
          # @return [Symbol] The name that is used for this node when visiting.
          def node_name
            :#{node_name}
          end

          # @return [Symbol] The method that is used on the visitor to visit nodes of this type.
          def visit_method
            :visit_#{node_name}
          end

          # @return [Symbol] The method name that determines if the parent is invalid.
          def invalid_child_method_name
            :"invalid_#{node_name}_child?"
          end

          # @return [Symbol] The method name that determines if the node is an invalid parent.
          def invalid_parent_method_name
            :"invalid_#{node_name}_parent?"
          end
        METHODS
      end

      # The child nodes of this node.
      #
      # @return [Array<Tree::Node>]
      attr_reader :children

      # Whether or not this node has child nodes.
      # This may be true even when \{#children} is empty,
      # in which case this node has an empty block (e.g. `{}`).
      #
      # @return [Boolean]
      attr_accessor :has_children

      # The line of the document on which this node appeared.
      #
      # @return [Integer]
      attr_accessor :line

      # The source range in the document on which this node appeared.
      #
      # @return [Sass::Source::Range]
      attr_accessor :source_range

      # The name of the document on which this node appeared.
      #
      # @return [String]
      attr_writer :filename

      # The options hash for the node.
      # See {file:SASS_REFERENCE.md#Options the Sass options documentation}.
      #
      # @return [{Symbol => Object}]
      attr_reader :options

      def initialize
        @children = []
        @filename = nil
        @options = nil
      end

      # Sets the options hash for the node and all its children.
      #
      # @param options [{Symbol => Object}] The options
      # @see #options
      def options=(options)
        Sass::Tree::Visitors::SetOptions.visit(self, options)
      end

      # @private
      def children=(children)
        self.has_children ||= !children.empty?
        @children = children
      end

      # The name of the document on which this node appeared.
      #
      # @return [String]
      def filename
        @filename || (@options && @options[:filename])
      end

      # Appends a child to the node.
      #
      # @param child [Tree::Node, Array<Tree::Node>] The child node or nodes
      # @raise [Sass::SyntaxError] if `child` is invalid
      def <<(child)
        return if child.nil?
        if child.is_a?(Array)
          child.each {|c| self << c}
        else
          self.has_children = true
          @children << child
        end
      end

      # Compares this node and another object (only other {Tree::Node}s will be equal).
      # This does a structural comparison;
      # if the contents of the nodes and all the child nodes are equivalent,
      # then the nodes are as well.
      #
      # Only static nodes need to override this.
      #
      # @param other [Object] The object to compare with
      # @return [Boolean] Whether or not this node and the other object
      #   are the same
      # @see Sass::Tree
      def ==(other)
        self.class == other.class && other.children == children
      end

      # True if \{#to\_s} will return `nil`;
      # that is, if the node shouldn't be rendered.
      # Should only be called in a static tree.
      #
      # @return [Boolean]
      def invisible?; false; end

      # The output style. See {file:SASS_REFERENCE.md#Options the Sass options documentation}.
      #
      # @return [Symbol]
      def style
        @options[:style]
      end

      # Computes the CSS corresponding to this static CSS tree.
      #
      # @return [String] The resulting CSS
      # @see Sass::Tree
      def css
        Sass::Tree::Visitors::ToCss.new.visit(self)
      end

      # Computes the CSS corresponding to this static CSS tree, along with
      # the respective source map.
      #
      # @return [(String, Sass::Source::Map)] The resulting CSS and the source map
      # @see Sass::Tree
      def css_with_sourcemap
        visitor = Sass::Tree::Visitors::ToCss.new(:build_source_mapping)
        result = visitor.visit(self)
        return result, visitor.source_mapping
      end

      # Returns a representation of the node for debugging purposes.
      #
      # @return [String]
      def inspect
        return self.class.to_s unless has_children
        "(#{self.class} #{children.map {|c| c.inspect}.join(' ')})"
      end

      # Iterates through each node in the tree rooted at this node
      # in a pre-order walk.
      #
      # @yield node
      # @yieldparam node [Node] a node in the tree
      def each
        yield self
        children.each {|c| c.each {|n| yield n}}
      end

      # Converts a node to Sass code that will generate it.
      #
      # @param options [{Symbol => Object}] An options hash (see {Sass::CSS#initialize})
      # @return [String] The Sass code corresponding to the node
      def to_sass(options = {})
        Sass::Tree::Visitors::Convert.visit(self, options, :sass)
      end

      # Converts a node to SCSS code that will generate it.
      #
      # @param options [{Symbol => Object}] An options hash (see {Sass::CSS#initialize})
      # @return [String] The Sass code corresponding to the node
      def to_scss(options = {})
        Sass::Tree::Visitors::Convert.visit(self, options, :scss)
      end

      # Return a deep clone of this node.
      # The child nodes are cloned, but options are not.
      #
      # @return [Node]
      def deep_copy
        Sass::Tree::Visitors::DeepCopy.visit(self)
      end

      # Whether or not this node bubbles up through RuleNodes.
      #
      # @return [Boolean]
      def bubbles?
        false
      end

      protected

      # @see Sass::Shared.balance
      # @raise [Sass::SyntaxError] if the brackets aren't balanced
      def balance(*args)
        res = Sass::Shared.balance(*args)
        return res if res
        raise Sass::SyntaxError.new("Unbalanced brackets.", :line => line)
      end
    end
  end
end
