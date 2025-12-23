# A visitor for converting a static Sass tree into a static CSS tree.
class Sass::Tree::Visitors::Cssize < Sass::Tree::Visitors::Base
  # @param root [Tree::Node] The root node of the tree to visit.
  # @return [(Tree::Node, Sass::Util::SubsetMap)] The resulting tree of static nodes
  #   *and* the extensions defined for this tree
  def self.visit(root); super; end

  protected

  # Returns the immediate parent of the current node.
  # @return [Tree::Node]
  def parent
    @parents.last
  end

  def initialize
    @parents = []
    @extends = Sass::Util::SubsetMap.new
  end

  # If an exception is raised, this adds proper metadata to the backtrace.
  def visit(node)
    super(node)
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:filename => node.filename, :line => node.line)
    raise e
  end

  # Keeps track of the current parent node.
  def visit_children(parent)
    with_parent parent do
      parent.children = visit_children_without_parent(parent)
      parent
    end
  end

  # Like {#visit\_children}, but doesn't set {#parent}.
  #
  # @param node [Sass::Tree::Node]
  # @return [Array<Sass::Tree::Node>] the flattened results of
  #   visiting all the children of `node`
  def visit_children_without_parent(node)
    node.children.map {|c| visit(c)}.flatten
  end

  # Runs a block of code with the current parent node
  # replaced with the given node.
  #
  # @param parent [Tree::Node] The new parent for the duration of the block.
  # @yield A block in which the parent is set to `parent`.
  # @return [Object] The return value of the block.
  def with_parent(parent)
    @parents.push parent
    yield
  ensure
    @parents.pop
  end

  # Converts the entire document to CSS.
  #
  # @return [(Tree::Node, Sass::Util::SubsetMap)] The resulting tree of static nodes
  #   *and* the extensions defined for this tree
  def visit_root(node)
    yield

    if parent.nil?
      imports_to_move = []
      import_limit = nil
      i = -1
      node.children.reject! do |n|
        i += 1
        if import_limit
          next false unless n.is_a?(Sass::Tree::CssImportNode)
          imports_to_move << n
          next true
        end

        if !n.is_a?(Sass::Tree::CommentNode) &&
            !n.is_a?(Sass::Tree::CharsetNode) &&
            !n.is_a?(Sass::Tree::CssImportNode)
          import_limit = i
        end

        false
      end

      if import_limit
        node.children = node.children[0...import_limit] + imports_to_move +
          node.children[import_limit..-1]
      end
    end

    return node, @extends
  rescue Sass::SyntaxError => e
    e.sass_template ||= node.template
    raise e
  end

  # A simple struct wrapping up information about a single `@extend` instance. A
  # single {ExtendNode} can have multiple Extends if either the parent node or
  # the extended selector is a comma sequence.
  #
  # @attr extender [Sass::Selector::Sequence]
  #   The selector of the CSS rule containing the `@extend`.
  # @attr target [Array<Sass::Selector::Simple>] The selector being `@extend`ed.
  # @attr node [Sass::Tree::ExtendNode] The node that produced this extend.
  # @attr directives [Array<Sass::Tree::DirectiveNode>]
  #   The directives containing the `@extend`.
  # @attr success [Boolean]
  #   Whether this extend successfully matched a selector.
  Extend = Struct.new(:extender, :target, :node, :directives, :success)

  # Registers an extension in the `@extends` subset map.
  def visit_extend(node)
    parent.resolved_rules.populate_extends(@extends, node.resolved_selector, node,
      @parents.select {|p| p.is_a?(Sass::Tree::DirectiveNode)})
    []
  end

  # Modifies exception backtraces to include the imported file.
  def visit_import(node)
    visit_children_without_parent(node)
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:filename => node.children.first.filename)
    e.add_backtrace(:filename => node.filename, :line => node.line)
    raise e
  end

  # Asserts that all the traced children are valid in their new location.
  def visit_trace(node)
    visit_children_without_parent(node)
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:mixin => node.name, :filename => node.filename, :line => node.line)
    e.add_backtrace(:filename => node.filename, :line => node.line)
    raise e
  end

  # Converts nested properties into flat properties
  # and updates the indentation of the prop node based on the nesting level.
  def visit_prop(node)
    if parent.is_a?(Sass::Tree::PropNode)
      node.resolved_name = "#{parent.resolved_name}-#{node.resolved_name}"
      node.tabs = parent.tabs + (parent.resolved_value.empty? ? 0 : 1) if node.style == :nested
    end

    yield

    result = node.children.dup
    if !node.resolved_value.empty? || node.children.empty?
      node.send(:check!)
      result.unshift(node)
    end

    result
  end

  def visit_atroot(node)
    # If there aren't any more directives or rules that this @at-root needs to
    # exclude, we can get rid of it and just evaluate the children.
    if @parents.none? {|n| node.exclude_node?(n)}
      results = visit_children_without_parent(node)
      results.each {|c| c.tabs += node.tabs if bubblable?(c)}
      if !results.empty? && bubblable?(results.last)
        results.last.group_end = node.group_end
      end
      return results
    end

    # If this @at-root excludes the immediate parent, return it as-is so that it
    # can be bubbled up by the parent node.
    return Bubble.new(node) if node.exclude_node?(parent)

    # Otherwise, duplicate the current parent and move it into the @at-root
    # node. As above, returning an @at-root node signals to the parent directive
    # that it should be bubbled upwards.
    bubble(node)
  end

  # The following directives are visible and have children. This means they need
  # to be able to handle bubbling up nodes such as @at-root and @media.

  # Updates the indentation of the rule node based on the nesting
  # level. The selectors were resolved in {Perform}.
  def visit_rule(node)
    yield

    rules = node.children.select {|c| bubblable?(c)}
    props = node.children.reject {|c| bubblable?(c) || c.invisible?}

    unless props.empty?
      node.children = props
      rules.each {|r| r.tabs += 1} if node.style == :nested
      rules.unshift(node)
    end

    rules = debubble(rules)
    unless parent.is_a?(Sass::Tree::RuleNode) || rules.empty? || !bubblable?(rules.last)
      rules.last.group_end = true
    end
    rules
  end

  def visit_keyframerule(node)
    return node unless node.has_children

    yield

    debubble(node.children, node)
  end

  # Bubbles a directive up through RuleNodes.
  def visit_directive(node)
    return node unless node.has_children
    if parent.is_a?(Sass::Tree::RuleNode)
      # @keyframes shouldn't include the rule nodes, so we manually create a
      # bubble that doesn't have the parent's contents for them.
      return node.normalized_name == '@keyframes' ? Bubble.new(node) : bubble(node)
    end

    yield

    # Since we don't know if the mere presence of an unknown directive may be
    # important, we should keep an empty version around even if all the contents
    # are removed via @at-root. However, if the contents are just bubbled out,
    # we don't need to do so.
    directive_exists = node.children.any? do |child|
      next true unless child.is_a?(Bubble)
      next false unless child.node.is_a?(Sass::Tree::DirectiveNode)
      child.node.resolved_value == node.resolved_value
    end

    # We know empty @keyframes directives do nothing.
    if directive_exists || node.name == '@keyframes'
      []
    else
      empty_node = node.dup
      empty_node.children = []
      [empty_node]
    end + debubble(node.children, node)
  end

  # Bubbles the `@media` directive up through RuleNodes
  # and merges it with other `@media` directives.
  def visit_media(node)
    return bubble(node) if parent.is_a?(Sass::Tree::RuleNode)
    return Bubble.new(node) if parent.is_a?(Sass::Tree::MediaNode)

    yield

    debubble(node.children, node) do |child|
      next child unless child.is_a?(Sass::Tree::MediaNode)
      # Copies of `node` can be bubbled, and we don't want to merge it with its
      # own query.
      next child if child.resolved_query == node.resolved_query
      next child if child.resolved_query = child.resolved_query.merge(node.resolved_query)
    end
  end

  # Bubbles the `@supports` directive up through RuleNodes.
  def visit_supports(node)
    return node unless node.has_children
    return bubble(node) if parent.is_a?(Sass::Tree::RuleNode)

    yield

    debubble(node.children, node)
  end

  private

  # "Bubbles" `node` one level by copying the parent and wrapping `node`'s
  # children with it.
  #
  # @param node [Sass::Tree::Node].
  # @return [Bubble]
  def bubble(node)
    new_rule = parent.dup
    new_rule.children = node.children
    node.children = [new_rule]
    Bubble.new(node)
  end

  # Pops all bubbles in `children` and intersperses the results with the other
  # values.
  #
  # If `parent` is passed, it's copied and used as the parent node for the
  # nested portions of `children`.
  #
  # @param children [List<Sass::Tree::Node, Bubble>]
  # @param parent [Sass::Tree::Node]
  # @yield [node] An optional block for processing bubbled nodes. Each bubbled
  #   node will be passed to this block.
  # @yieldparam node [Sass::Tree::Node] A bubbled node.
  # @yieldreturn [Sass::Tree::Node?] A node to use in place of the bubbled node.
  #   This can be the node itself, or `nil` to indicate that the node should be
  #   omitted.
  # @return [List<Sass::Tree::Node, Bubble>]
  def debubble(children, parent = nil)
    # Keep track of the previous parent so that we don't divide `parent`
    # unnecessarily if the `@at-root` doesn't produce any new nodes (e.g.
    # `@at-root {@extend %foo}`).
    previous_parent = nil

    Sass::Util.slice_by(children) {|c| c.is_a?(Bubble)}.map do |(is_bubble, slice)|
      unless is_bubble
        next slice unless parent
        if previous_parent
          previous_parent.children.push(*slice)
          next []
        else
          previous_parent = new_parent = parent.dup
          new_parent.children = slice
          next new_parent
        end
      end

      slice.map do |bubble|
        next unless (node = block_given? ? yield(bubble.node) : bubble.node)
        node.tabs += bubble.tabs
        node.group_end = bubble.group_end
        results = [visit(node)].flatten
        previous_parent = nil unless results.empty?
        results
      end.compact
    end.flatten
  end

  # Returns whether or not a node can be bubbled up through the syntax tree.
  #
  # @param node [Sass::Tree::Node]
  # @return [Boolean]
  def bubblable?(node)
    node.is_a?(Sass::Tree::RuleNode) || node.bubbles?
  end

  # A wrapper class for a node that indicates to the parent that it should
  # treat the wrapped node as a sibling rather than a child.
  #
  # Nodes should be wrapped before they're passed to \{Cssize.visit}. They will
  # be automatically visited upon calling \{#pop}.
  #
  # This duck types as a [Sass::Tree::Node] for the purposes of
  # tree-manipulation operations.
  class Bubble
    attr_accessor :node
    attr_accessor :tabs
    attr_accessor :group_end

    def initialize(node)
      @node = node
      @tabs = 0
    end

    def bubbles?
      true
    end

    def inspect
      "(Bubble #{node.inspect})"
    end
  end
end
