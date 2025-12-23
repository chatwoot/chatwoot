module Regexp::Syntax
  module Token
    module Assertion
      Lookahead = %i[lookahead nlookahead]
      Lookbehind = %i[lookbehind nlookbehind]

      All = Lookahead + Lookbehind
      Type = :assertion
    end

    Map[Assertion::Type] = Assertion::All
  end
end
