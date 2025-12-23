module Regexp::Expression
  # A sequence of expressions. Differs from a Subexpressions by how it handles
  # quantifiers, as it applies them to its last element instead of itself as
  # a whole subexpression.
  #
  # Used as the base class for the Alternation alternatives, Conditional
  # branches, and CharacterSet::Intersection intersected sequences.
  class Sequence < Regexp::Expression::Subexpression
    class << self
      def add_to(exp, params = {}, active_opts = {})
        sequence = construct(
          level:             exp.level,
          set_level:         exp.set_level,
          conditional_level: params[:conditional_level] || exp.conditional_level,
          ts:                params[:ts],
        )
        sequence.options = active_opts
        exp.expressions << sequence
        sequence
      end
    end

    def ts
      (head = expressions.first) ? head.ts : @ts
    end

    def quantify(token, *args)
      extract_quantifier_target(token.text).quantify(token, *args)
    end
  end
end
