module Sass::Script::Value
  # The abstract superclass for SassScript objects.
  #
  # Many of these methods, especially the ones that correspond to SassScript operations,
  # are designed to be overridden by subclasses which may change the semantics somewhat.
  # The operations listed here are just the defaults.
  class Base
    # Returns the Ruby value of the value.
    # The type of this value varies based on the subclass.
    #
    # @return [Object]
    attr_reader :value

    # The source range in the document on which this node appeared.
    #
    # @return [Sass::Source::Range]
    attr_accessor :source_range

    # Creates a new value.
    #
    # @param value [Object] The object for \{#value}
    def initialize(value = nil)
      value.freeze unless value.nil? || value == true || value == false
      @value = value
      @options = nil
    end

    # Sets the options hash for this node,
    # as well as for all child nodes.
    # See {file:SASS_REFERENCE.md#Options the Sass options documentation}.
    #
    # @param options [{Symbol => Object}] The options
    attr_writer :options

    # Returns the options hash for this node.
    #
    # @return [{Symbol => Object}]
    # @raise [Sass::SyntaxError] if the options hash hasn't been set.
    #   This should only happen when the value was created
    #   outside of the parser and \{#to\_s} was called on it
    def options
      return @options if @options
      raise Sass::SyntaxError.new(<<MSG)
The #options attribute is not set on this #{self.class}.
  This error is probably occurring because #to_s was called
  on this value within a custom Sass function without first
  setting the #options attribute.
MSG
    end

    # The SassScript `==` operation.
    # **Note that this returns a {Sass::Script::Value::Bool} object,
    # not a Ruby boolean**.
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Sass::Script::Value::Bool] True if this value is the same as the other,
    #   false otherwise
    def eq(other)
      Sass::Script::Value::Bool.new(self.class == other.class && value == other.value)
    end

    # The SassScript `!=` operation.
    # **Note that this returns a {Sass::Script::Value::Bool} object,
    # not a Ruby boolean**.
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Sass::Script::Value::Bool] False if this value is the same as the other,
    #   true otherwise
    def neq(other)
      Sass::Script::Value::Bool.new(!eq(other).to_bool)
    end

    # The SassScript `==` operation.
    # **Note that this returns a {Sass::Script::Value::Bool} object,
    # not a Ruby boolean**.
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Sass::Script::Value::Bool] True if this value is the same as the other,
    #   false otherwise
    def unary_not
      Sass::Script::Value::Bool.new(!to_bool)
    end

    # The SassScript `=` operation
    # (used for proprietary MS syntax like `alpha(opacity=20)`).
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Script::Value::String] A string containing both values
    #   separated by `"="`
    def single_eq(other)
      Sass::Script::Value::String.new("#{self}=#{other}")
    end

    # The SassScript `+` operation.
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Script::Value::String] A string containing both values
    #   without any separation
    def plus(other)
      type = other.is_a?(Sass::Script::Value::String) ? other.type : :identifier
      Sass::Script::Value::String.new(to_s(:quote => :none) + other.to_s(:quote => :none), type)
    end

    # The SassScript `-` operation.
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Script::Value::String] A string containing both values
    #   separated by `"-"`
    def minus(other)
      Sass::Script::Value::String.new("#{self}-#{other}")
    end

    # The SassScript `/` operation.
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Script::Value::String] A string containing both values
    #   separated by `"/"`
    def div(other)
      Sass::Script::Value::String.new("#{self}/#{other}")
    end

    # The SassScript unary `+` operation (e.g. `+$a`).
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Script::Value::String] A string containing the value
    #   preceded by `"+"`
    def unary_plus
      Sass::Script::Value::String.new("+#{self}")
    end

    # The SassScript unary `-` operation (e.g. `-$a`).
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Script::Value::String] A string containing the value
    #   preceded by `"-"`
    def unary_minus
      Sass::Script::Value::String.new("-#{self}")
    end

    # The SassScript unary `/` operation (e.g. `/$a`).
    #
    # @param other [Value] The right-hand side of the operator
    # @return [Script::Value::String] A string containing the value
    #   preceded by `"/"`
    def unary_div
      Sass::Script::Value::String.new("/#{self}")
    end

    # Returns the hash code of this value. Two objects' hash codes should be
    # equal if the objects are equal.
    #
    # @return [Integer for Ruby 2.4.0+, Fixnum for earlier Ruby versions] The hash code.
    def hash
      value.hash
    end

    def eql?(other)
      self == other
    end

    # @return [String] A readable representation of the value
    def inspect
      value.inspect
    end

    # @return [Boolean] `true` (the Ruby boolean value)
    def to_bool
      true
    end

    # Compares this object with another.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean] Whether or not this value is equivalent to `other`
    def ==(other)
      eq(other).to_bool
    end

    # @return [Integer] The integer value of this value
    # @raise [Sass::SyntaxError] if this value isn't an integer
    def to_i
      raise Sass::SyntaxError.new("#{inspect} is not an integer.")
    end

    # @raise [Sass::SyntaxError] if this value isn't an integer
    def assert_int!; to_i; end

    # Returns the separator for this value. For non-list-like values or the
    # empty list, this will be `nil`. For lists or maps, it will be `:space` or
    # `:comma`.
    #
    # @return [Symbol]
    def separator; nil; end

    # Whether the value is surrounded by square brackets. For non-list values,
    # this will be `false`.
    #
    # @return [Boolean]
    def bracketed; false; end

    # Returns the value of this value as a list.
    # Single values are considered the same as single-element lists.
    #
    # @return [Array<Value>] This value as a list
    def to_a
      [self]
    end

    # Returns the value of this value as a hash. Most values don't have hash
    # representations, but [Map]s and empty [List]s do.
    #
    # @return [Hash<Value, Value>] This value as a hash
    # @raise [Sass::SyntaxError] if this value doesn't have a hash representation
    def to_h
      raise Sass::SyntaxError.new("#{inspect} is not a map.")
    end

    # Returns the string representation of this value
    # as it would be output to the CSS document.
    #
    # @options opts :quote [String]
    #   The preferred quote style for quoted strings. If `:none`, strings are
    #   always emitted unquoted.
    # @return [String]
    def to_s(opts = {})
      Sass::Util.abstract(self)
    end
    alias_method :to_sass, :to_s

    # Returns whether or not this object is null.
    #
    # @return [Boolean] `false`
    def null?
      false
    end

    # Creates a new list containing `contents` but with the same brackets and
    # separators as this object, when interpreted as a list.
    #
    # @param contents [Array<Value>] The contents of the new list.
    # @param separator [Symbol] The separator of the new list. Defaults to \{#separator}.
    # @param bracketed [Boolean] Whether the new list is bracketed. Defaults to \{#bracketed}.
    # @return [Sass::Script::Value::List]
    def with_contents(contents, separator: self.separator, bracketed: self.bracketed)
      Sass::Script::Value::List.new(contents, separator: separator, bracketed: bracketed)
    end

    protected

    # Evaluates the value.
    #
    # @param environment [Sass::Environment] The environment in which to evaluate the SassScript
    # @return [Value] This value
    def _perform(environment)
      self
    end
  end
end
