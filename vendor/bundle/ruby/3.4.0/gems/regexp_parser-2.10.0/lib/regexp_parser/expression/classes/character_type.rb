module Regexp::Expression
  module CharacterType
    class Base < Regexp::Expression::Base; end

    class Any              < CharacterType::Base; end
    class Digit            < CharacterType::Base; end
    class NonDigit         < CharacterType::Base; end
    class Hex              < CharacterType::Base; end
    class NonHex           < CharacterType::Base; end
    class Word             < CharacterType::Base; end
    class NonWord          < CharacterType::Base; end
    class Space            < CharacterType::Base; end
    class NonSpace         < CharacterType::Base; end
    class Linebreak        < CharacterType::Base; end
    class ExtendedGrapheme < CharacterType::Base; end
  end
end
