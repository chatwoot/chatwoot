require 'sass/scss/rx'

module Sass
  # SassScript is code that's embedded in Sass documents
  # to allow for property values to be computed from variables.
  #
  # This module contains code that handles the parsing and evaluation of SassScript.
  module Script
    # The regular expression used to parse variables.
    MATCH = /^\$(#{Sass::SCSS::RX::IDENT})\s*:\s*(.+?)
      (!#{Sass::SCSS::RX::IDENT}(?:\s+!#{Sass::SCSS::RX::IDENT})*)?$/x

    # The regular expression used to validate variables without matching.
    VALIDATE = /^\$#{Sass::SCSS::RX::IDENT}$/

    # Parses a string of SassScript
    #
    # @param value [String] The SassScript
    # @param line [Integer] The number of the line on which the SassScript appeared.
    #   Used for error reporting
    # @param offset [Integer] The number of characters in on `line` that the SassScript started.
    #   Used for error reporting
    # @param options [{Symbol => Object}] An options hash;
    #   see {file:SASS_REFERENCE.md#Options the Sass options documentation}
    # @return [Script::Tree::Node] The root node of the parse tree
    def self.parse(value, line, offset, options = {})
      Parser.parse(value, line, offset, options)
    rescue Sass::SyntaxError => e
      e.message << ": #{value.inspect}." if e.message == "SassScript error"
      e.modify_backtrace(:line => line, :filename => options[:filename])
      raise e
    end

    require 'sass/script/functions'
    require 'sass/script/parser'
    require 'sass/script/tree'
    require 'sass/script/value'

    # @private
    CONST_RENAMES = {
      :Literal => Sass::Script::Value::Base,
      :ArgList => Sass::Script::Value::ArgList,
      :Bool => Sass::Script::Value::Bool,
      :Color => Sass::Script::Value::Color,
      :List => Sass::Script::Value::List,
      :Null => Sass::Script::Value::Null,
      :Number => Sass::Script::Value::Number,
      :String => Sass::Script::Value::String,
      :Node => Sass::Script::Tree::Node,
      :Funcall => Sass::Script::Tree::Funcall,
      :Interpolation => Sass::Script::Tree::Interpolation,
      :Operation => Sass::Script::Tree::Operation,
      :StringInterpolation => Sass::Script::Tree::StringInterpolation,
      :UnaryOperation => Sass::Script::Tree::UnaryOperation,
      :Variable => Sass::Script::Tree::Variable,
    }

    # @private
    def self.const_missing(name)
      klass = CONST_RENAMES[name]
      super unless klass
      CONST_RENAMES.each {|n, k| const_set(n, k)}
      klass
    end
  end
end
