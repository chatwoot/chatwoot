# frozen_string_literal: true

# The abstract superclass for SassScript objects.
# Many of these methods, especially the ones that correspond to SassScript operations,
# are designed to be overridden by subclasses which may change the semantics somewhat.
# The operations listed here are just the defaults.

class SassC::Script::Value

  # Returns the pure Ruby value of the value.
  # The type of this value varies based on the subclass.
  attr_reader :value

  # The source range in the document on which this node appeared.
  attr_accessor :source_range

  # Creates a new value.
  def initialize(value = nil)
    value.freeze unless value.nil? || value == true || value == false
    @value = value
    @options = nil
  end

  # Sets the options hash for this node,
  # as well as for all child nodes.
  # See the official Sass reference for options.
  attr_writer :options

  # Returns the options hash for this node.
  # Raises SassC::SyntaxError if the value was created
  # outside of the parser and \{#to\_s} was called on it
  def options
    return @options if @options
    raise SassC::SyntaxError.new("The #options attribute is not set on this #{self.class}. This error is probably occurring because #to_s was called on this value within a custom Sass function without first setting the #options attribute.")
  end

  # Returns the hash code of this value. Two objects' hash codes should be
  # equal if the objects are equal.
  def hash
    value.hash
  end

  # True if this Value is the same as `other`
  def eql?(other)
    self == other
  end

  # Returns a system inspect value for this object
  def inspect
    value.inspect
  end

  # Returns `true` (all Values are truthy)
  def to_bool
    true
  end

  # Compares this object to `other`
  def ==(other)
    self.class == other.class && value == other.value
  end

  # Returns the integer value of this value.
  # Raises SassC::SyntaxError if this value doesn’t implment integer conversion.
  def to_i
    raise SassC::SyntaxError.new("#{inspect} is not an integer.")
  end

  # @raise [SassC::SyntaxError] if this value isn't an integer
  def assert_int!; to_i; end

  # Returns the separator for this value. For non-list-like values or the
  # empty list, this will be `nil`. For lists or maps, it will be `:space` or `:comma`.
  def separator
    nil
  end

  # Whether the value is surrounded by square brackets. For non-list values,
  # this will be `false`.
  def bracketed
    false
  end

  # Returns the value of this Value as an array.
  # Single Values are considered the same as single-element arrays.
  def to_a
    [self]
  end

  # Returns the value of this value as a hash. Most values don't have hash
  # representations, but [Map]s and empty [List]s do.
  #
  # @return [Hash<Value, Value>] This value as a hash
  # @raise [SassC::SyntaxError] if this value doesn't have a hash representation
  def to_h
    raise SassC::SyntaxError.new("#{inspect} is not a map.")
  end

  # Returns the string representation of this value
  # as it would be output to the CSS document.
  #
  # @options opts :quote [String]
  #   The preferred quote style for quoted strings. If `:none`, strings are
  #   always emitted unquoted.
  # @return [String]
  def to_s(opts = {})
    SassC::Util.abstract(self)
  end
  alias_method :to_sass, :to_s

  # Returns `false` (all Values are truthy)
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
    SassC::Script::Value::List.new(contents, separator: separator, bracketed: bracketed)
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
