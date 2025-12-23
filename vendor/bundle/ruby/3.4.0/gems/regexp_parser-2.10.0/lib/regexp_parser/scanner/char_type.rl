%%{
  machine re_char_type;

  single_codepoint_char_type = [dDhHsSwW];
  multi_codepoint_char_type  = [RX];

  char_type_char = single_codepoint_char_type | multi_codepoint_char_type;

  # Char types scanner
  # --------------------------------------------------------------------------
  char_type := |*
    char_type_char {
      case text = copy(data, ts-1, te)
      when '\d'; emit(:type, :digit,      text)
      when '\D'; emit(:type, :nondigit,   text)
      when '\h'; emit(:type, :hex,        text)
      when '\H'; emit(:type, :nonhex,     text)
      when '\s'; emit(:type, :space,      text)
      when '\S'; emit(:type, :nonspace,   text)
      when '\w'; emit(:type, :word,       text)
      when '\W'; emit(:type, :nonword,    text)
      when '\R'; emit(:type, :linebreak,  text)
      when '\X'; emit(:type, :xgrapheme,  text)
      end
      fret;
    };
  *|;
}%%
