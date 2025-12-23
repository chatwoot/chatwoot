%%{
  machine re_property;

  property_char     = [pP];

  property_sequence = property_char . '{' . '^'? (alnum|space|[_\-\.=])+ '}';

  action premature_property_end {
    raise PrematureEndError.new('unicode property')
  }

  # Unicode properties scanner
  # --------------------------------------------------------------------------
  unicode_property := |*

    property_sequence < eof(premature_property_end) {
      text = copy(data, ts-1, te)
      type = (text[1] == 'P') ^ (text[3] == '^') ? :nonproperty : :property

      name = text[3..-2].gsub(/[\^\s_\-]/, '').downcase

      token = self.class.short_prop_map[name] || self.class.long_prop_map[name]
      raise ValidationError.for(:property, name) unless token

      self.emit(type, token.to_sym, text)

      fret;
    };
  *|;
}%%
