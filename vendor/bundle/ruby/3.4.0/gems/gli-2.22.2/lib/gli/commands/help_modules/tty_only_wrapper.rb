module GLI
  module Commands
    module HelpModules
      # Formats text in one line, stripping newlines and NOT wrapping
      class TTYOnlyWrapper
        # Args are ignored entirely; this keeps it consistent with the TextWrapper interface
        def initialize(width,indent)
          @proxy = if STDOUT.tty?
                     TextWrapper.new(width,indent)
                   else
                     OneLineWrapper.new(width,indent)
                   end
        end

        # Return a wrapped version of text, assuming that the first line has already been
        # indented by @indent characters.  Resulting text does NOT have a newline in it.
        def wrap(text)
          @proxy.wrap(text)
        end
      end
    end
  end
end
