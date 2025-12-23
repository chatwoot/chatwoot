# Visitors are used to traverse the Sass parse tree.
# Visitors should extend {Visitors::Base},
# which provides a small amount of scaffolding for traversal.
module Sass::Tree::Visitors
  # The abstract base class for Sass visitors.
  # Visitors should extend this class,
  # then implement `visit_*` methods for each node they care about
  # (e.g. `visit_rule` for {RuleNode} or `visit_for` for {ForNode}).
  # These methods take the node in question as argument.
  # They may `yield` to visit the child nodes of the current node.
  #
  # *Note*: due to the unusual nature of {Sass::Tree::IfNode},
  # special care must be taken to ensure that it is properly handled.
  # In particular, there is no built-in scaffolding
  # for dealing with the return value of `@else` nodes.
  #
  # @abstract
  class Base
    # Runs the visitor on a tree.
    #
    # @param root [Tree::Node] The root node of the Sass tree.
    # @return [Object] The return value of \{#visit} for the root node.
    def self.visit(root)
      new.send(:visit, root)
    end

    protected

    # Runs the visitor on the given node.
    # This can be overridden by subclasses that need to do something for each node.
    #
    # @param node [Tree::Node] The node to visit.
    # @return [Object] The return value of the `visit_*` method for this node.
    def visit(node)
      if respond_to?(node.class.visit_method, true)
        send(node.class.visit_method, node) {visit_children(node)}
      else
        visit_children(node)
      end
    end

    # Visit the child nodes for a given node.
    # This can be overridden by subclasses that need to do something
    # with the child nodes' return values.
    #
    # This method is run when `visit_*` methods `yield`,
    # and its return value is returned from the `yield`.
    #
    # @param parent [Tree::Node] The parent node of the children to visit.
    # @return [Array<Object>] The return values of the `visit_*` methods for the children.
    def visit_children(parent)
      parent.children.map {|c| visit(c)}
    end

    # Returns the name of a node as used in the `visit_*` method.
    #
    # @param [Tree::Node] node The node.
    # @return [String] The name.
    def self.node_name(node)
      Sass::Util.deprecated(self, "Call node.class.node_name instead.")
      node.class.node_name
    end

    # `yield`s, then runs the visitor on the `@else` clause if the node has one.
    # This exists to ensure that the contents of the `@else` clause get visited.
    def visit_if(node)
      yield
      visit(node.else) if node.else
      node
    end
  end
end
