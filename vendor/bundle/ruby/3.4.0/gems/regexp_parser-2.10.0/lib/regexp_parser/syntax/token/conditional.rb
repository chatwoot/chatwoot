module Regexp::Syntax
  module Token
    module Conditional
      Delimiters = %i[open close]

      Condition  = %i[condition_open condition condition_close]
      Separator  = %i[separator]

      All = Conditional::Delimiters + Conditional::Condition + Conditional::Separator

      Type = :conditional
    end

    Map[Conditional::Type] = Conditional::All
  end
end
