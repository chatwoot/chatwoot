module GLI
  module Commands
    module HelpModules
      # Leaves text formatting exactly as it was received. Doesn't strip anything.
      class VerbatimWrapper
        # Args are ignored entirely; this keeps it consistent with the TextWrapper interface
        def initialize(width,indent)
        end

        def wrap(text)
          return String(text)
        end
      end
    end
  end
end
