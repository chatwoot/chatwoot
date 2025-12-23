# typed: strict

class Prism::Source
  sig { returns(String) }
  def source; end

  sig { returns(Integer) }
  def start_line; end

  sig { returns(T::Array[Integer]) }
  def offsets; end

  sig { params(source: String, start_line: Integer, offsets: T::Array[Integer]).void }
  def initialize(source, start_line = 1, offsets = []); end

  sig { params(start_line: Integer).void }
  def replace_start_line(start_line); end

  sig { params(offsets: T::Array[Integer]).void }
  def replace_offsets(offsets); end

  sig { returns(Encoding) }
  def encoding; end

  sig { returns(T::Array[String]) }
  def lines; end

  sig { params(byte_offset: Integer, length: Integer).returns(String) }
  def slice(byte_offset, length); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def line(byte_offset); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def line_start(byte_offset); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def column(byte_offset); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def character_offset(byte_offset); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def character_column(byte_offset); end

  sig { params(byte_offset: Integer, encoding: Encoding).returns(Integer) }
  def code_units_offset(byte_offset, encoding); end

  sig { params(encoding: Encoding).returns(T.any(Prism::CodeUnitsCache, T.proc.params(byte_offset: Integer).returns(Integer))) }
  def code_units_cache(encoding); end

  sig { params(byte_offset: Integer, encoding: Encoding).returns(Integer) }
  def code_units_column(byte_offset, encoding); end
end

class Prism::CodeUnitsCache
  sig { params(source: String, encoding: Encoding).void }
  def initialize(source, encoding); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def [](byte_offset); end
end

class Prism::ASCIISource < Prism::Source
  sig { params(byte_offset: Integer).returns(Integer) }
  def character_offset(byte_offset); end

  sig { params(byte_offset: Integer).returns(Integer) }
  def character_column(byte_offset); end

  sig { params(byte_offset: Integer, encoding: Encoding).returns(Integer) }
  def code_units_offset(byte_offset, encoding); end

  sig { params(encoding: Encoding).returns(T.any(Prism::CodeUnitsCache, T.proc.params(byte_offset: Integer).returns(Integer))) }
  def code_units_cache(encoding); end

  sig { params(byte_offset: Integer, encoding: Encoding).returns(Integer) }
  def code_units_column(byte_offset, encoding); end
end

class Prism::Location
  sig { returns(Prism::Source) }
  def source; end

  sig { returns(Integer) }
  def start_offset; end

  sig { returns(Integer) }
  def length; end

  sig { params(source: Prism::Source, start_offset: Integer, length: Integer).void }
  def initialize(source, start_offset, length); end

  sig { returns(T::Array[Prism::Comment]) }
  def leading_comments; end

  sig { params(comment: Prism::Comment).void }
  def leading_comment(comment); end

  sig { returns(T::Array[Prism::Comment]) }
  def trailing_comments; end

  sig { params(comment: Prism::Comment).void }
  def trailing_comment(comment); end

  sig { returns(T::Array[Prism::Comment]) }
  def comments; end

  sig { params(source: Prism::Source, start_offset: Integer, length: Integer).returns(Prism::Location) }
  def copy(source: self.source, start_offset: self.start_offset, length: self.length); end

  sig { returns(Prism::Location) }
  def chop; end

  sig { returns(String) }
  def inspect; end

  sig { returns(T::Array[String]) }
  def source_lines; end

  sig { returns(String) }
  def slice; end

  sig { returns(Integer) }
  def start_character_offset; end

  sig { params(encoding: Encoding).returns(Integer) }
  def start_code_units_offset(encoding = Encoding::UTF_16LE); end

  sig { params(cache: T.any(Prism::CodeUnitsCache, T.proc.params(byte_offset: Integer).returns(Integer))).returns(Integer) }
  def cached_start_code_units_offset(cache); end

  sig { returns(Integer) }
  def end_offset; end

  sig { returns(Integer) }
  def end_character_offset; end

  sig { params(encoding: Encoding).returns(Integer) }
  def end_code_units_offset(encoding = Encoding::UTF_16LE); end

  sig { params(cache: T.any(Prism::CodeUnitsCache, T.proc.params(byte_offset: Integer).returns(Integer))).returns(Integer) }
  def cached_end_code_units_offset(cache); end

  sig { returns(Integer) }
  def start_line; end

  sig { returns(String) }
  def start_line_slice; end

  sig { returns(Integer) }
  def end_line; end

  sig { returns(Integer) }
  def start_column; end

  sig { returns(Integer) }
  def start_character_column; end

  sig { params(encoding: Encoding).returns(Integer) }
  def start_code_units_column(encoding = Encoding::UTF_16LE); end

  sig { params(cache: T.any(Prism::CodeUnitsCache, T.proc.params(byte_offset: Integer).returns(Integer))).returns(Integer) }
  def cached_start_code_units_column(cache); end

  sig { returns(Integer) }
  def end_column; end

  sig { returns(Integer) }
  def end_character_column; end

  sig { params(encoding: Encoding).returns(Integer) }
  def end_code_units_column(encoding = Encoding::UTF_16LE); end

  sig { params(cache: T.any(Prism::CodeUnitsCache, T.proc.params(byte_offset: Integer).returns(Integer))).returns(Integer) }
  def cached_end_code_units_column(cache); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { params(q: T.untyped).void }
  def pretty_print(q); end

  sig { params(other: T.untyped).returns(T::Boolean) }
  def ==(other); end

  sig { params(other: Prism::Location).returns(Prism::Location) }
  def join(other); end

  sig { params(string: String).returns(Prism::Location) }
  def adjoin(string); end
end

class Prism::Comment
  abstract!

  sig { returns(Prism::Location) }
  def location; end

  sig { params(location: Prism::Location).void }
  def initialize(location); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(String) }
  def slice; end

  sig { abstract.returns(T::Boolean) }
  def trailing?; end
end

class Prism::InlineComment < Prism::Comment
  sig { override.returns(T::Boolean) }
  def trailing?; end

  sig { returns(String) }
  def inspect; end
end

class Prism::EmbDocComment < Prism::Comment
  sig { override.returns(T::Boolean) }
  def trailing?; end

  sig { returns(String) }
  def inspect; end
end

class Prism::MagicComment
  sig { returns(Prism::Location) }
  def key_loc; end

  sig { returns(Prism::Location) }
  def value_loc; end

  sig { params(key_loc: Prism::Location, value_loc: Prism::Location).void }
  def initialize(key_loc, value_loc); end

  sig { returns(String) }
  def key; end

  sig { returns(String) }
  def value; end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(String) }
  def inspect; end
end

class Prism::ParseError
  sig { returns(Symbol) }
  def type; end

  sig { returns(String) }
  def message; end

  sig { returns(Prism::Location) }
  def location; end

  sig { returns(Symbol) }
  def level; end

  sig { params(type: Symbol, message: String, location: Prism::Location, level: Symbol).void }
  def initialize(type, message, location, level); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(String) }
  def inspect; end
end

class Prism::ParseWarning
  sig { returns(Symbol) }
  def type; end

  sig { returns(String) }
  def message; end

  sig { returns(Prism::Location) }
  def location; end

  sig { returns(Symbol) }
  def level; end

  sig { params(type: Symbol, message: String, location: Prism::Location, level: Symbol).void }
  def initialize(type, message, location, level); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(String) }
  def inspect; end
end

class Prism::Result
  sig { params(comments: T::Array[Prism::Comment], magic_comments: T::Array[Prism::MagicComment], data_loc: T.nilable(Prism::Location), errors: T::Array[Prism::ParseError], warnings: T::Array[Prism::ParseWarning], source: Prism::Source).void }
  def initialize(comments, magic_comments, data_loc, errors, warnings, source); end

  sig { returns(T::Array[Prism::Comment]) }
  def comments; end

  sig { returns(T::Array[Prism::MagicComment]) }
  def magic_comments; end

  sig { returns(T.nilable(Prism::Location)) }
  def data_loc; end

  sig { returns(T::Array[Prism::ParseError]) }
  def errors; end

  sig { returns(T::Array[Prism::ParseWarning]) }
  def warnings; end

  sig { returns(Prism::Source) }
  def source; end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(Encoding) }
  def encoding; end

  sig { returns(T::Boolean) }
  def success?; end

  sig { returns(T::Boolean) }
  def failure?; end

  sig { params(encoding: Encoding).returns(T.any(Prism::CodeUnitsCache, T.proc.params(byte_offset: Integer).returns(Integer))) }
  def code_units_cache(encoding); end
end

class Prism::ParseResult < Prism::Result
  sig { params(value: Prism::ProgramNode, comments: T::Array[Prism::Comment], magic_comments: T::Array[Prism::MagicComment], data_loc: T.nilable(Prism::Location), errors: T::Array[Prism::ParseError], warnings: T::Array[Prism::ParseWarning], source: Prism::Source).void }
  def initialize(value, comments, magic_comments, data_loc, errors, warnings, source); end

  sig { returns(Prism::ProgramNode) }
  def value; end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end
end

class Prism::LexResult < Prism::Result
  sig { params(value: T::Array[T.untyped], comments: T::Array[Prism::Comment], magic_comments: T::Array[Prism::MagicComment], data_loc: T.nilable(Prism::Location), errors: T::Array[Prism::ParseError], warnings: T::Array[Prism::ParseWarning], source: Prism::Source).void }
  def initialize(value, comments, magic_comments, data_loc, errors, warnings, source); end

  sig { returns(T::Array[T.untyped]) }
  def value; end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end
end

class Prism::ParseLexResult < Prism::Result
  sig { params(value: [Prism::ProgramNode, T::Array[T.untyped]], comments: T::Array[Prism::Comment], magic_comments: T::Array[Prism::MagicComment], data_loc: T.nilable(Prism::Location), errors: T::Array[Prism::ParseError], warnings: T::Array[Prism::ParseWarning], source: Prism::Source).void }
  def initialize(value, comments, magic_comments, data_loc, errors, warnings, source); end

  sig { returns([Prism::ProgramNode, T::Array[T.untyped]]) }
  def value; end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end
end

class Prism::Token
  sig { returns(Prism::Source) }
  def source; end

  sig { returns(Symbol) }
  def type; end

  sig { returns(String) }
  def value; end

  sig { params(source: Prism::Source, type: Symbol, value: String, location: T.any(Integer, Prism::Location)).void }
  def initialize(source, type, value, location); end

  sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
  def deconstruct_keys(keys); end

  sig { returns(Prism::Location) }
  def location; end

  sig { params(q: T.untyped).void }
  def pretty_print(q); end

  sig { params(other: T.untyped).returns(T::Boolean) }
  def ==(other); end
end

class Prism::Scope
  sig { returns(T::Array[Symbol]) }
  def locals; end

  sig { returns(T::Array[Symbol]) }
  def forwarding; end

  sig { params(locals: T::Array[Symbol], forwarding: T::Array[Symbol]).void }
  def initialize(locals, forwarding); end
end
