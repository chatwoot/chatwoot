# typed: strict

module Prism::Reflection
end

class Prism::Reflection::Field
  sig { params(name: Symbol).void }
  def initialize(name); end

  sig { returns(Symbol) }
  def name; end
end

class Prism::Reflection::NodeField < Prism::Reflection::Field
end

class Prism::Reflection::OptionalNodeField < Prism::Reflection::Field
end

class Prism::Reflection::NodeListField < Prism::Reflection::Field
end

class Prism::Reflection::ConstantField < Prism::Reflection::Field
end

class Prism::Reflection::OptionalConstantField < Prism::Reflection::Field
end

class Prism::Reflection::ConstantListField < Prism::Reflection::Field
end

class Prism::Reflection::StringField < Prism::Reflection::Field
end

class Prism::Reflection::LocationField < Prism::Reflection::Field
end

class Prism::Reflection::OptionalLocationField < Prism::Reflection::Field
end

class Prism::Reflection::IntegerField < Prism::Reflection::Field
end

class Prism::Reflection::FloatField < Prism::Reflection::Field
end

class Prism::Reflection::FlagsField < Prism::Reflection::Field
  sig { params(name: Symbol, flags: T::Array[Symbol]).void }
  def initialize(name, flags); end

  sig { returns(T::Array[Symbol]) }
  def flags; end
end

module Prism::Reflection
  sig { params(node: T.class_of(Prism::Node)).returns(T::Array[Prism::Reflection::Field]) }
  def self.fields_for(node); end
end
