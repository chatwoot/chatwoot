# A visitor for setting options on the Sass tree
class Sass::Tree::Visitors::SetOptions < Sass::Tree::Visitors::Base
  # @param root [Tree::Node] The root node of the tree to visit.
  # @param options [{Symbol => Object}] The options has to set.
  def self.visit(root, options); new(options).send(:visit, root); end

  protected

  def initialize(options)
    @options = options
  end

  def visit(node)
    node.instance_variable_set('@options', @options)
    super
  end

  def visit_comment(node)
    node.value.each {|c| c.options = @options if c.is_a?(Sass::Script::Tree::Node)}
    yield
  end

  def visit_debug(node)
    node.expr.options = @options
    yield
  end

  def visit_error(node)
    node.expr.options = @options
    yield
  end

  def visit_each(node)
    node.list.options = @options
    yield
  end

  def visit_extend(node)
    node.selector.each {|c| c.options = @options if c.is_a?(Sass::Script::Tree::Node)}
    yield
  end

  def visit_for(node)
    node.from.options = @options
    node.to.options = @options
    yield
  end

  def visit_function(node)
    node.args.each do |k, v|
      k.options = @options
      v.options = @options if v
    end
    node.splat.options = @options if node.splat
    yield
  end

  def visit_if(node)
    node.expr.options = @options if node.expr
    visit(node.else) if node.else
    yield
  end

  def visit_import(node)
    # We have no good way of propagating the new options through an Engine
    # instance, so we just null it out. This also lets us avoid caching an
    # imported Engine along with the importing source tree.
    node.imported_file = nil
    yield
  end

  def visit_mixindef(node)
    node.args.each do |k, v|
      k.options = @options
      v.options = @options if v
    end
    node.splat.options = @options if node.splat
    yield
  end

  def visit_mixin(node)
    node.args.each {|a| a.options = @options}
    node.keywords.each {|_k, v| v.options = @options}
    node.splat.options = @options if node.splat
    node.kwarg_splat.options = @options if node.kwarg_splat
    yield
  end

  def visit_prop(node)
    node.name.each {|c| c.options = @options if c.is_a?(Sass::Script::Tree::Node)}
    node.value.each {|c| c.options = @options if c.is_a?(Sass::Script::Tree::Node)}
    yield
  end

  def visit_return(node)
    node.expr.options = @options
    yield
  end

  def visit_rule(node)
    node.rule.each {|c| c.options = @options if c.is_a?(Sass::Script::Tree::Node)}
    yield
  end

  def visit_variable(node)
    node.expr.options = @options
    yield
  end

  def visit_warn(node)
    node.expr.options = @options
    yield
  end

  def visit_while(node)
    node.expr.options = @options
    yield
  end

  def visit_directive(node)
    node.value.each {|c| c.options = @options if c.is_a?(Sass::Script::Tree::Node)}
    yield
  end

  def visit_media(node)
    node.query.each {|c| c.options = @options if c.is_a?(Sass::Script::Tree::Node)}
    yield
  end

  def visit_cssimport(node)
    node.query.each {|c| c.options = @options if c.is_a?(Sass::Script::Tree::Node)} if node.query
    yield
  end

  def visit_supports(node)
    node.condition.options = @options
    yield
  end
end
