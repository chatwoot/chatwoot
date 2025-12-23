# typed: strict

class Prism::InterpolatedMatchLastLineNode < Prism::Node
  sig { returns(Integer) }
  def options; end
end

class Prism::InterpolatedRegularExpressionNode < Prism::Node
  sig { returns(Integer) }
  def options; end
end

class Prism::MatchLastLineNode < Prism::Node
  sig { returns(Integer) }
  def options; end
end

class Prism::RegularExpressionNode < Prism::Node
  sig { returns(Integer) }
  def options; end
end

class Prism::InterpolatedStringNode < Prism::Node
  sig { returns(T::Boolean) }
  def heredoc?; end
end

class Prism::InterpolatedXStringNode < Prism::Node
  sig { returns(T::Boolean) }
  def heredoc?; end
end

class Prism::StringNode < Prism::Node
  sig { returns(T::Boolean) }
  def heredoc?; end

  sig { returns(Prism::InterpolatedStringNode) }
  def to_interpolated; end
end

class Prism::XStringNode < Prism::Node
  sig { returns(T::Boolean) }
  def heredoc?; end

  sig { returns(Prism::InterpolatedXStringNode) }
  def to_interpolated; end
end

class Prism::ImaginaryNode < Prism::Node
  sig { returns(Complex) }
  def value; end
end

class Prism::RationalNode < Prism::Node
  sig { returns(Rational) }
  def value; end
end

class Prism::ConstantReadNode < Prism::Node
  sig { returns(T::Array[Symbol]) }
  def full_name_parts; end

  sig { returns(String) }
  def full_name; end
end

class Prism::ConstantWriteNode < Prism::Node
  sig { returns(T::Array[Symbol]) }
  def full_name_parts; end

  sig { returns(String) }
  def full_name; end
end

class Prism::ConstantPathNode < Prism::Node
  sig { returns(T::Array[Symbol]) }
  def full_name_parts; end

  sig { returns(String) }
  def full_name; end
end

class Prism::ConstantPathTargetNode < Prism::Node
  sig { returns(T::Array[Symbol]) }
  def full_name_parts; end

  sig { returns(String) }
  def full_name; end
end

class Prism::ConstantTargetNode < Prism::Node
  sig { returns(T::Array[Symbol]) }
  def full_name_parts; end

  sig { returns(String) }
  def full_name; end
end

class Prism::ParametersNode < Prism::Node
  sig { returns(T::Array[T.any([Symbol, Symbol], [Symbol])]) }
  def signature; end
end

class Prism::CallNode < Prism::Node
  sig { returns(T.nilable(Prism::Location)) }
  def full_message_loc; end
end
