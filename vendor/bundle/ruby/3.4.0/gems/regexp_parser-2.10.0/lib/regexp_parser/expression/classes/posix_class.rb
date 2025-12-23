module Regexp::Expression
  class PosixClass < Regexp::Expression::Base
    def name
      text[/\w+/]
    end
  end

  # alias for symmetry between token symbol and Expression class name
  Posixclass    = PosixClass
  Nonposixclass = PosixClass
end
