class Regexp::Syntax::V1_8_6 < Regexp::Syntax::Base
  implements :anchor,     Anchor::All
  implements :assertion,  Assertion::Lookahead
  implements :backref,    Backreference::V1_8_6
  implements :escape,     Escape::Basic + Escape::ASCII + Escape::Meta + Escape::Control
  implements :free_space, FreeSpace::All
  implements :group,      Group::V1_8_6
  implements :literal,    Literal::All
  implements :meta,       Meta::Extended
  implements :posixclass, PosixClass::Standard
  implements :quantifier, Quantifier::V1_8_6
  implements :set,        CharacterSet::All
  implements :type,       CharacterType::Extended
end
