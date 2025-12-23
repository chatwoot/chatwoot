module Regexp::Syntax
  module Token
    module PosixClass
      Standard = %i[alnum alpha blank cntrl digit graph
                    lower print punct space upper xdigit]

      Extensions = %i[ascii word]

      All = Standard + Extensions
      Type = :posixclass
      NonType = :nonposixclass
    end

    Map[PosixClass::Type]    = PosixClass::All
    Map[PosixClass::NonType] = PosixClass::All
  end
end
