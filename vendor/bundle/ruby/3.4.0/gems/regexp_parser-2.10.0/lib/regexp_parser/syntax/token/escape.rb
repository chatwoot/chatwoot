module Regexp::Syntax
  module Token
    module Escape
      Basic = %i[backslash literal]

      Control = %i[control meta_sequence]

      ASCII = %i[bell backspace escape form_feed newline carriage
                 tab vertical_tab]

      Unicode = %i[codepoint codepoint_list]

      Meta  = %i[dot alternation
                 zero_or_one zero_or_more one_or_more
                 bol eol
                 group_open group_close
                 interval_open interval_close
                 set_open set_close]

      Hex   = %i[hex]

      Octal = %i[octal]

      All   = Basic + Control + ASCII + Unicode + Meta + Hex + Octal
      Type  = :escape
    end

    Map[Escape::Type] = Escape::All

    # alias for symmetry between Token::* and Expression::*
    EscapeSequence = Escape
  end
end
