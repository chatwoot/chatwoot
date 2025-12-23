module Regexp::Syntax
  module Token
    module CharacterSet
      Basic     = %i[open close negate range]
      Extended  = Basic + %i[intersection]

      All = Extended
      Type = :set
    end

    Map[CharacterSet::Type] = CharacterSet::All

    # alias for symmetry between token symbol and Token module name
    Set = CharacterSet
  end
end
