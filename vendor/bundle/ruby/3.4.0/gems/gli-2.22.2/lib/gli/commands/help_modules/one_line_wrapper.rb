module GLI
  module Commands
    module HelpModules
      # Formats text in one line, stripping newlines and NOT wrapping
      class OneLineWrapper
        # Args are ignored entirely; this keeps it consistent with the TextWrapper interface
        def initialize(width,indent)
        end

        # Return a wrapped version of text, assuming that the first line has already been
        # indented by @indent characters.  Resulting text does NOT have a newline in it.
        def wrap(text)
          return String(text).gsub(/\n+/,' ').strip
        end
      end
    end
  end
end
