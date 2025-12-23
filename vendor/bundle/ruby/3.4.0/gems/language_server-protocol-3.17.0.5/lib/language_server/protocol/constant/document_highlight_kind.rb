module LanguageServer
  module Protocol
    module Constant
      #
      # A document highlight kind.
      #
      module DocumentHighlightKind
        #
        # A textual occurrence.
        #
        TEXT = 1
        #
        # Read-access of a symbol, like reading a variable.
        #
        READ = 2
        #
        # Write-access of a symbol, like writing to a variable.
        #
        WRITE = 3
      end
    end
  end
end
