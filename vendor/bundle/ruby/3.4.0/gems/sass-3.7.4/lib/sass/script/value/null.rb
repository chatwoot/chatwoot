module Sass::Script::Value
  # A SassScript object representing a null value.
  class Null < Base
    # The null value in SassScript.
    #
    # This is assigned before new is overridden below so that we use the default implementation.
    NULL = new(nil)

    # We override object creation so that users of the core API
    # will not need to know that null is a specific constant.
    #
    # @private
    # @return [Null] the {NULL} constant.
    def self.new
      NULL
    end

    # @return [Boolean] `false` (the Ruby boolean value)
    def to_bool
      false
    end

    # @return [Boolean] `true`
    def null?
      true
    end

    # @return [String] '' (An empty string)
    def to_s(opts = {})
      ''
    end

    def to_sass(opts = {})
      'null'
    end

    # Returns a string representing a null value.
    #
    # @return [String]
    def inspect
      'null'
    end
  end
end
