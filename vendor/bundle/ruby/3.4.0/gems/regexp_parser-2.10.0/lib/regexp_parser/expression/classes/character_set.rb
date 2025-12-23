module Regexp::Expression
  class CharacterSet < Regexp::Expression::Subexpression
    attr_accessor :closed, :negative
    alias :closed? :closed

    def initialize(token, options = {})
      self.negative = false
      self.closed   = false
      super
    end

    def negate
      self.negative = true
    end

    def close
      self.closed = true
    end
  end

  # alias for symmetry between token symbol and Expression class name
  Set = CharacterSet
end # module Regexp::Expression
