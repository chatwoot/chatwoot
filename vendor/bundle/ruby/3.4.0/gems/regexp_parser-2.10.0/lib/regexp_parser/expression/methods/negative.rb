module Regexp::Expression
  module Shared
    def negative?
      false
    end

    # not an alias so as to respect overrides of #negative?
    def negated?
      negative?
    end
  end

  Anchor::NonWordBoundary.class_eval       { def negative?; true                          end }
  Assertion::NegativeLookahead.class_eval  { def negative?; true                          end }
  Assertion::NegativeLookbehind.class_eval { def negative?; true                          end }
  CharacterSet.class_eval                  { def negative?; negative                      end }
  CharacterType::Base.class_eval           { def negative?; token.to_s.start_with?('non') end }
  PosixClass.class_eval                    { def negative?; type == :nonposixclass        end }
  UnicodeProperty::Base.class_eval         { def negative?; type == :nonproperty          end }
end
