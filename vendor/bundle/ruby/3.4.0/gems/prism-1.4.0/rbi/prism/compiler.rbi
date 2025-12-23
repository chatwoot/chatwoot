# typed: strict

class Prism::Compiler
  sig { params(node: T.nilable(Prism::Node)).returns(T.untyped) }
  def visit(node); end

  sig { params(nodes: T::Array[T.nilable(Prism::Node)]).returns(T::Array[T.untyped]) }
  def visit_all(nodes); end

  sig { params(node: Prism::Node).returns(T::Array[T.untyped]) }
  def visit_child_nodes(node); end
end
