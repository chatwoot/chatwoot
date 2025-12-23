module LanguageServer
  module Protocol
    module Constant
      #
      # Defines how the host (editor) should sync document changes to the language
      # server.
      #
      module TextDocumentSyncKind
        #
        # Documents should not be synced at all.
        #
        NONE = 0
        #
        # Documents are synced by always sending the full content
        # of the document.
        #
        FULL = 1
        #
        # Documents are synced by sending the full content on open.
        # After that only incremental updates to the document are
        # sent.
        #
        INCREMENTAL = 2
      end
    end
  end
end
