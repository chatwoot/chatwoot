module Regexp::Syntax
  module Token
    module Quantifier
      Greedy = %i[
        zero_or_one
        zero_or_more
        one_or_more
      ]

      Reluctant = %i[
        zero_or_one_reluctant
        zero_or_more_reluctant
        one_or_more_reluctant
      ]

      Possessive = %i[
        zero_or_one_possessive
        zero_or_more_possessive
        one_or_more_possessive
      ]

      Interval             = %i[interval]
      IntervalReluctant    = %i[interval_reluctant]
      IntervalPossessive   = %i[interval_possessive]

      IntervalAll = Interval + IntervalReluctant + IntervalPossessive

      V1_8_6 = Greedy + Reluctant + Interval + IntervalReluctant
      All = Greedy + Reluctant + Possessive + IntervalAll
      Type = :quantifier
    end

    Map[Quantifier::Type] = Quantifier::All
  end
end
