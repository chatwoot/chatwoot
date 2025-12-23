module Regexp::Expression
  # A sequence of expressions, used by Alternation as one of its alternatives.
  class Alternative < Regexp::Expression::Sequence; end

  class Alternation < Regexp::Expression::SequenceOperation
    OPERAND = Alternative

    alias :alternatives :expressions
  end
end
