module Regexp::Syntax
  module Token
    module Virtual
      Root     = %i[root]
      Sequence = %i[sequence]

      All  = %i[root sequence]
      Type = :expression
    end
  end
end
