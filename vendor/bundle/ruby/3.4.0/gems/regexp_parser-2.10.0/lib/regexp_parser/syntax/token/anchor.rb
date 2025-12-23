module Regexp::Syntax
  module Token
    module Anchor
      Basic       = %i[bol eol]
      Extended    = Basic + %i[word_boundary nonword_boundary]
      String      = %i[bos eos eos_ob_eol]
      MatchStart  = %i[match_start]

      All = Extended + String + MatchStart
      Type = :anchor
    end

    Map[Anchor::Type] = Anchor::All
  end
end
