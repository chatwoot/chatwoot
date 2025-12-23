# typed: strict

class Prism::StringQuery
  sig { params(string: String).returns(T::Boolean) }
  def self.local?(string); end

  sig { params(string: String).returns(T::Boolean) }
  def self.constant?(string); end

  sig { params(string: String).returns(T::Boolean) }
  def self.method_name?(string); end
end
