module Regexp::Syntax
  module Token
    module Backreference
      Plain     = %i[number]
      NumberRef = %i[number_ref number_rel_ref]
      Number    = Plain + NumberRef
      Name      = %i[name_ref]

      RecursionLevel = %i[name_recursion_ref number_recursion_ref]

      V1_8_6 = Plain

      V1_9_1 = Name + NumberRef + RecursionLevel

      All = V1_8_6 + V1_9_1
      Type = :backref
    end

    # Type is the same as Backreference so keeping it here, for now.
    module SubexpressionCall
      Name      = %i[name_call]
      Number    = %i[number_call number_rel_call]

      All = Name + Number
    end

    Map[Backreference::Type] = Backreference::All +
                               SubexpressionCall::All

    # alias for symmetry between token symbol and Expression class name
    Backref = Backreference
  end
end
