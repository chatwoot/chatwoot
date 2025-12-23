module Regexp::Expression
  module UnicodeProperty
    class Base < Regexp::Expression::Base
      def name
        text[/\A\\[pP]\{([^}]+)\}\z/, 1]
      end

      def shortcut
        Regexp::Scanner.short_prop_map.key(token.to_s)
      end
    end

    class Alnum         < Base; end
    class Alpha         < Base; end
    class Ascii         < Base; end
    class Blank         < Base; end
    class Cntrl         < Base; end
    class Digit         < Base; end
    class Graph         < Base; end
    class Lower         < Base; end
    class Print         < Base; end
    class Punct         < Base; end
    class Space         < Base; end
    class Upper         < Base; end
    class Word          < Base; end
    class Xdigit        < Base; end
    class XPosixPunct   < Base; end

    class Newline       < Base; end

    class Any           < Base; end
    class Assigned      < Base; end

    module Letter
      class Base < UnicodeProperty::Base; end

      class Any         < Letter::Base; end
      class Cased       < Letter::Base; end
      class Uppercase   < Letter::Base; end
      class Lowercase   < Letter::Base; end
      class Titlecase   < Letter::Base; end
      class Modifier    < Letter::Base; end
      class Other       < Letter::Base; end
    end

    module Mark
      class Base < UnicodeProperty::Base; end

      class Any         < Mark::Base; end
      class Combining   < Mark::Base; end
      class Nonspacing  < Mark::Base; end
      class Spacing     < Mark::Base; end
      class Enclosing   < Mark::Base; end
    end

    module Number
      class Base < UnicodeProperty::Base; end

      class Any         < Number::Base; end
      class Decimal     < Number::Base; end
      class Letter      < Number::Base; end
      class Other       < Number::Base; end
    end

    module Punctuation
      class Base < UnicodeProperty::Base; end

      class Any         < Punctuation::Base; end
      class Connector   < Punctuation::Base; end
      class Dash        < Punctuation::Base; end
      class Open        < Punctuation::Base; end
      class Close       < Punctuation::Base; end
      class Initial     < Punctuation::Base; end
      class Final       < Punctuation::Base; end
      class Other       < Punctuation::Base; end
    end

    module Separator
      class Base < UnicodeProperty::Base; end

      class Any         < Separator::Base; end
      class Space       < Separator::Base; end
      class Line        < Separator::Base; end
      class Paragraph   < Separator::Base; end
    end

    module Symbol
      class Base < UnicodeProperty::Base; end

      class Any         < Symbol::Base; end
      class Math        < Symbol::Base; end
      class Currency    < Symbol::Base; end
      class Modifier    < Symbol::Base; end
      class Other       < Symbol::Base; end
    end

    module Codepoint
      class Base < UnicodeProperty::Base; end

      class Any         < Codepoint::Base; end
      class Control     < Codepoint::Base; end
      class Format      < Codepoint::Base; end
      class Surrogate   < Codepoint::Base; end
      class PrivateUse  < Codepoint::Base; end
      class Unassigned  < Codepoint::Base; end
    end

    class Age        < UnicodeProperty::Base; end
    class Block      < UnicodeProperty::Base; end
    class Derived    < UnicodeProperty::Base; end
    class Emoji      < UnicodeProperty::Base; end
    class Enumerated < UnicodeProperty::Base; end
    class Script     < UnicodeProperty::Base; end
  end

  # alias for symmetry between token symbol and Expression class name
  Property    = UnicodeProperty
  Nonproperty = UnicodeProperty
end # module Regexp::Expression
