module Regexp::Expression::EscapeSequence
  AsciiEscape.class_eval { def codepoint; 0x1B end }
  Backspace.class_eval   { def codepoint; 0x8  end }
  Bell.class_eval        { def codepoint; 0x7  end }
  FormFeed.class_eval    { def codepoint; 0xC  end }
  Newline.class_eval     { def codepoint; 0xA  end }
  Return.class_eval      { def codepoint; 0xD  end }
  Tab.class_eval         { def codepoint; 0x9  end }
  VerticalTab.class_eval { def codepoint; 0xB  end }

  Literal.class_eval     { def codepoint; text[1].ord end }

  Octal.class_eval       { def codepoint; text[/\d+/].to_i(8) end }

  Hex.class_eval         { def codepoint; text[/\h+/].hex end }
  Codepoint.class_eval   { def codepoint; text[/\h+/].hex end }

  CodepointList.class_eval do
    # Maybe this should be a unique top-level expression class?
    def char
      raise NoMethodError, 'CodepointList responds only to #chars'
    end

    def codepoint
      raise NoMethodError, 'CodepointList responds only to #codepoints'
    end

    def chars
      codepoints.map { |cp| cp.chr('utf-8') }
    end

    def codepoints
      text.scan(/\h+/).map(&:hex)
    end
  end

  AbstractMetaControlSequence.class_eval do
    private

    def control_sequence_to_s(control_sequence)
      five_lsb = control_sequence.unpack('B*').first[-5..-1]
      ["000#{five_lsb}"].pack('B*')
    end

    def meta_char_to_codepoint(meta_char)
      byte_value = meta_char.ord
      byte_value < 128 ? byte_value + 128 : byte_value
    end
  end

  Control.class_eval do
    def codepoint
      control_sequence_to_s(text).ord
    end
  end

  Meta.class_eval do
    def codepoint
      meta_char_to_codepoint(text[-1])
    end
  end

  MetaControl.class_eval do
    def codepoint
      meta_char_to_codepoint(control_sequence_to_s(text))
    end
  end
end
