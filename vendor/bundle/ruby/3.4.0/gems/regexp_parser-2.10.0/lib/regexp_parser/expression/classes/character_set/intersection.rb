module Regexp::Expression
  class CharacterSet < Regexp::Expression::Subexpression
    class IntersectedSequence < Regexp::Expression::Sequence; end

    class Intersection < Regexp::Expression::SequenceOperation
      OPERAND = IntersectedSequence
    end
  end
end
