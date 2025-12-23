# A visitor for copying the full structure of a Sass tree.
class Sass::Tree::Visitors::DeepCopy < Sass::Tree::Visitors::Base
  protected

  def visit(node)
    super(node.dup)
  end

  def visit_children(parent)
    parent.children = parent.children.map {|c| visit(c)}
    parent
  end

  def visit_debug(node)
    node.expr = node.expr.deep_copy
    yield
  end

  def visit_error(node)
    node.expr = node.expr.deep_copy
    yield
  end

  def visit_each(node)
    node.list = node.list.deep_copy
    yield
  end

  def visit_extend(node)
    node.selector = node.selector.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.deep_copy : c}
    yield
  end

  def visit_for(node)
    node.from = node.from.deep_copy
    node.to = node.to.deep_copy
    yield
  end

  def visit_function(node)
    node.args = node.args.map {|k, v| [k.deep_copy, v && v.deep_copy]}
    yield
  end

  def visit_if(node)
    node.expr = node.expr.deep_copy if node.expr
    node.else = visit(node.else) if node.else
    yield
  end

  def visit_mixindef(node)
    node.args = node.args.map {|k, v| [k.deep_copy, v && v.deep_copy]}
    yield
  end

  def visit_mixin(node)
    node.args = node.args.map {|a| a.deep_copy}
    node.keywords = Sass::Util::NormalizedMap.new(Hash[node.keywords.map {|k, v| [k, v.deep_copy]}])
    yield
  end

  def visit_prop(node)
    node.name = node.name.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.deep_copy : c}
    node.value = node.value.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.deep_copy : c}
    yield
  end

  def visit_return(node)
    node.expr = node.expr.deep_copy
    yield
  end

  def visit_rule(node)
    node.rule = node.rule.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.deep_copy : c}
    yield
  end

  def visit_variable(node)
    node.expr = node.expr.deep_copy
    yield
  end

  def visit_warn(node)
    node.expr = node.expr.deep_copy
    yield
  end

  def visit_while(node)
    node.expr = node.expr.deep_copy
    yield
  end

  def visit_directive(node)
    node.value = node.value.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.deep_copy : c}
    yield
  end

  def visit_media(node)
    node.query = node.query.map {|c| c.is_a?(Sass::Script::Tree::Node) ? c.deep_copy : c}
    yield
  end

  def visit_supports(node)
    node.condition = node.condition.deep_copy
    yield
  end
end
