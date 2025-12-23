# frozen_string_literal: true

# A SassScript object representing a boolean (true or false) value.

class SassC::Script::Value::Bool < SassC::Script::Value

  # The true value in SassScript.
  # This is assigned before new is overridden below so that we use the default implementation.
  TRUE = new(true)

  # The false value in SassScript.
  # This is assigned before new is overridden below so that we use the default implementation.
  FALSE = new(false)

  # We override object creation so that users of the core API
  # will not need to know that booleans are specific constants.
  # Tests `value` for truthiness and returns the TRUE or FALSE constant.
  def self.new(value)
    value ? TRUE : FALSE
  end

  # The pure Ruby value of this Boolean
  attr_reader :value
  alias_method :to_bool, :value

  # Returns the string "true" or "false" for this value
  def to_s(opts = {})
    @value.to_s
  end
  alias_method :to_sass, :to_s

end
