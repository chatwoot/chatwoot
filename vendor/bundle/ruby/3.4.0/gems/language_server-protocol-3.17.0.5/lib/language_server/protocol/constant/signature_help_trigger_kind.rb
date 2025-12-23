module LanguageServer
  module Protocol
    module Constant
      #
      # How a signature help was triggered.
      #
      module SignatureHelpTriggerKind
        #
        # Signature help was invoked manually by the user or by a command.
        #
        INVOKED = 1
        #
        # Signature help was triggered by a trigger character.
        #
        TRIGGER_CHARACTER = 2
        #
        # Signature help was triggered by the cursor moving or by the document
        # content changing.
        #
        CONTENT_CHANGE = 3
      end
    end
  end
end
