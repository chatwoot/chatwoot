Regexp::Expression::EscapeSequence::Base.class_eval do
  def char
    codepoint.chr('utf-8')
  end
end
