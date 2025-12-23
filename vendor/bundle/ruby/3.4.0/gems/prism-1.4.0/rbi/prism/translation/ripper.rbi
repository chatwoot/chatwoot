# typed: strict

class Prism::Translation::Ripper < Prism::Compiler
  sig { returns(T::Boolean) }
  def error?; end

  sig { returns(T.untyped) }
  def parse; end

  sig { params(source: String, filename: String, lineno: Integer, raise_errors: T.untyped).returns(T.untyped) }
  def self.sexp_raw(source, filename = "-", lineno = 1, raise_errors: false); end

  sig { params(source: String, filename: String, lineno: Integer, raise_errors: T.untyped).returns(T.untyped) }
  def self.sexp(source, filename = "-", lineno = 1, raise_errors: false); end
end
