module Regexp::Expression
  module EscapeSequence
    Base        = Class.new(Regexp::Expression::Base)

    AsciiEscape = Class.new(Base) # \e
    Backspace   = Class.new(Base) # \b
    Bell        = Class.new(Base) # \a
    FormFeed    = Class.new(Base) # \f
    Newline     = Class.new(Base) # \n
    Return      = Class.new(Base) # \r
    Tab         = Class.new(Base) # \t
    VerticalTab = Class.new(Base) # \v

    Literal     = Class.new(Base) # e.g. \j, \@, \😀 (ineffectual escapes)

    Octal       = Class.new(Base) # e.g. \012
    Hex         = Class.new(Base) # e.g. \x0A
    Codepoint   = Class.new(Base) # e.g. \u000A

    CodepointList = Class.new(Base) # e.g. \u{A B}

    AbstractMetaControlSequence = Class.new(Base)
    Control                     = Class.new(AbstractMetaControlSequence) # e.g. \cB
    Meta                        = Class.new(AbstractMetaControlSequence) # e.g. \M-Z
    MetaControl                 = Class.new(AbstractMetaControlSequence) # e.g. \M-\cX
  end

  # alias for symmetry between Token::* and Expression::*
  Escape = EscapeSequence
end
