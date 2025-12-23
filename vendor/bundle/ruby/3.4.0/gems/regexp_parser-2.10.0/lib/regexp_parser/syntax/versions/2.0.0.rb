class Regexp::Syntax::V2_0_0 < Regexp::Syntax::V1_9_3
  implements :keep,        Keep::All
  implements :conditional, Conditional::All
  implements :property,    UnicodeProperty::V2_0_0
  implements :nonproperty, UnicodeProperty::V2_0_0
  implements :type,        CharacterType::Clustered

  excludes   :property,    %i[newline]
  excludes   :nonproperty, %i[newline]
end
