module LanguageServer
  module Protocol
    module Constant
      #
      # The diagnostic tags.
      #
      module DiagnosticTag
        #
        # Unused or unnecessary code.
        #
        # Clients are allowed to render diagnostics with this tag faded out
        # instead of having an error squiggle.
        #
        UNNECESSARY = 1
        #
        # Deprecated or obsolete code.
        #
        # Clients are allowed to rendered diagnostics with this tag strike through.
        #
        DEPRECATED = 2
      end
    end
  end
end
