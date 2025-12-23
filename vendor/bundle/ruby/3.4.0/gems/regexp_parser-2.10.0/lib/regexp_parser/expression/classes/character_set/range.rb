module Regexp::Expression
  class CharacterSet < Regexp::Expression::Subexpression
    class Range < Regexp::Expression::Subexpression
      def ts
        (head = expressions.first) ? head.ts : @ts
      end

      def <<(exp)
        complete? and raise Regexp::Parser::Error,
          "Can't add more than 2 expressions to a Range"
        super
      end

      def complete?
        count == 2
      end
    end
  end
end
