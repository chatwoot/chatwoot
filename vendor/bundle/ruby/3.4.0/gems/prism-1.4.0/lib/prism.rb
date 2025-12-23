# frozen_string_literal: true

# The Prism Ruby parser.
#
# "Parsing Ruby is suddenly manageable!"
#   - You, hopefully
#
module Prism
  # There are many files in prism that are templated to handle every node type,
  # which means the files can end up being quite large. We autoload them to make
  # our require speed faster since consuming libraries are unlikely to use all
  # of these features.

  autoload :BasicVisitor, "prism/visitor"
  autoload :Compiler, "prism/compiler"
  autoload :DesugarCompiler, "prism/desugar_compiler"
  autoload :Dispatcher, "prism/dispatcher"
  autoload :DotVisitor, "prism/dot_visitor"
  autoload :DSL, "prism/dsl"
  autoload :InspectVisitor, "prism/inspect_visitor"
  autoload :LexCompat, "prism/lex_compat"
  autoload :LexRipper, "prism/lex_compat"
  autoload :MutationCompiler, "prism/mutation_compiler"
  autoload :Pack, "prism/pack"
  autoload :Pattern, "prism/pattern"
  autoload :Reflection, "prism/reflection"
  autoload :Relocation, "prism/relocation"
  autoload :Serialize, "prism/serialize"
  autoload :StringQuery, "prism/string_query"
  autoload :Translation, "prism/translation"
  autoload :Visitor, "prism/visitor"

  # Some of these constants are not meant to be exposed, so marking them as
  # private here.

  private_constant :LexCompat
  private_constant :LexRipper

  # :call-seq:
  #   Prism::lex_compat(source, **options) -> LexCompat::Result
  #
  # Returns a parse result whose value is an array of tokens that closely
  # resembles the return value of Ripper::lex. The main difference is that the
  # `:on_sp` token is not emitted.
  #
  # For supported options, see Prism::parse.
  def self.lex_compat(source, **options)
    LexCompat.new(source, **options).result # steep:ignore
  end

  # :call-seq:
  #   Prism::lex_ripper(source) -> Array
  #
  # This lexes with the Ripper lex. It drops any space events but otherwise
  # returns the same tokens. Raises SyntaxError if the syntax in source is
  # invalid.
  def self.lex_ripper(source)
    LexRipper.new(source).result # steep:ignore
  end

  # :call-seq:
  #   Prism::load(source, serialized, freeze) -> ParseResult
  #
  # Load the serialized AST using the source as a reference into a tree.
  def self.load(source, serialized, freeze = false)
    Serialize.load_parse(source, serialized, freeze)
  end
end

require_relative "prism/polyfill/byteindex"
require_relative "prism/node"
require_relative "prism/node_ext"
require_relative "prism/parse_result"

# This is a Ruby implementation of the prism parser. If we're running on CRuby
# and we haven't explicitly set the PRISM_FFI_BACKEND environment variable, then
# it's going to require the built library. Otherwise, it's going to require a
# module that uses FFI to call into the library.
if RUBY_ENGINE == "ruby" and !ENV["PRISM_FFI_BACKEND"]
  # The C extension is the default backend on CRuby.
  Prism::BACKEND = :CEXT

  require "prism/prism"
else
  # The FFI backend is used on other Ruby implementations.
  Prism::BACKEND = :FFI

  require_relative "prism/ffi"
end
