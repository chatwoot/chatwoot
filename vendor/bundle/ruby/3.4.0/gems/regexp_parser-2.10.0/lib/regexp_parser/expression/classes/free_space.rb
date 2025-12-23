module Regexp::Expression
  class FreeSpace < Regexp::Expression::Base
    def quantify(*_args)
      raise Regexp::Parser::Error, 'Can not quantify a free space object'
    end
  end

  class Comment < Regexp::Expression::FreeSpace
  end

  class WhiteSpace < Regexp::Expression::FreeSpace
    def merge(exp)
      warn("#{self.class}##{__method__} is deprecated and will be removed in v3.0.0.")
      text << exp.text
    end
  end
end
