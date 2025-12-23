module LanguageServer
  module Protocol
    module Constant
      #
      # Represents reasons why a text document is saved.
      #
      module TextDocumentSaveReason
        #
        # Manually triggered, e.g. by the user pressing save, by starting
        # debugging, or by an API call.
        #
        MANUAL = 1
        #
        # Automatic after a delay.
        #
        AFTER_DELAY = 2
        #
        # When the editor lost focus.
        #
        FOCUS_OUT = 3
      end
    end
  end
end
