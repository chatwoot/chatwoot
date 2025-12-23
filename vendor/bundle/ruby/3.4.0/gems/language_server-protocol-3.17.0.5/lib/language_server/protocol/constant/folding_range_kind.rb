module LanguageServer
  module Protocol
    module Constant
      #
      # A set of predefined range kinds.
      # The type is a string since the value set is extensible
      #
      module FoldingRangeKind
        #
        # Folding range for a comment
        #
        COMMENT = 'comment'
        #
        # Folding range for imports or includes
        #
        IMPORTS = 'imports'
        #
        # Folding range for a region (e.g. `#region`)
        #
        REGION = 'region'
      end
    end
  end
end
