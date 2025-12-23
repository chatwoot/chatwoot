module Sass::Script::Value
  # A SassScript object representing a null value.
  class Callable < Base
    # Constructs a Callable value for use in SassScript.
    #
    # @param callable [Sass::Callable] The callable to be used when the
    # callable is called.
    def initialize(callable)
      super(callable)
    end

    def to_s(opts = {})
      raise Sass::SyntaxError.new("#{to_sass} isn't a valid CSS value.")
    end

    def inspect
      to_sass
    end

    # @abstract
    def to_sass
      Sass::Util.abstract(self)
    end
  end
end
