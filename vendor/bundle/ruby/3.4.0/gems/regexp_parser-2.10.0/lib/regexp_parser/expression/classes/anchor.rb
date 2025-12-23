module Regexp::Expression
  module Anchor
    class Base < Regexp::Expression::Base; end

    class BeginningOfLine               < Anchor::Base; end
    class EndOfLine                     < Anchor::Base; end

    class BeginningOfString             < Anchor::Base; end
    class EndOfString                   < Anchor::Base; end

    class EndOfStringOrBeforeEndOfLine  < Anchor::Base; end

    class WordBoundary                  < Anchor::Base; end
    class NonWordBoundary               < Anchor::Base; end

    class MatchStart                    < Anchor::Base; end

    BOL      = BeginningOfLine
    EOL      = EndOfLine
    BOS      = BeginningOfString
    EOS      = EndOfString
    EOSobEOL = EndOfStringOrBeforeEndOfLine
  end
end
