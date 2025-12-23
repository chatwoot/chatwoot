module Regexp::Syntax
  module Token
    module CharacterType
      Basic     = []
      Extended  = %i[digit nondigit space nonspace word nonword]
      Hex       = %i[hex nonhex]

      Clustered = %i[linebreak xgrapheme]

      All = Basic + Extended + Hex + Clustered
      Type = :type
    end

    Map[CharacterType::Type] = CharacterType::All
  end
end
