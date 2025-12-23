# typed: strict

class Prism::InspectVisitor < Prism::Visitor
  sig { params(indent: String).void }
  def initialize(indent = ""); end

  sig { params(node: Prism::Node).returns(String) }
  def self.compose(node); end

  sig { returns(String) }
  def compose; end
end
