module Regexp::Syntax
  module Token
    module Group
      Basic     = %i[capture close]
      Extended  = Basic + %i[options options_switch]

      Named     = %i[named]
      Atomic    = %i[atomic]
      Passive   = %i[passive]
      Comment   = %i[comment]

      V1_8_6 = Group::Extended + Group::Named + Group::Atomic +
               Group::Passive + Group::Comment

      V2_4_1 = %i[absence]

      All = V1_8_6 + V2_4_1
      Type = :group
    end

    Map[Group::Type] = Group::All
  end
end
