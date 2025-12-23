module LanguageServer
  module Protocol
    module Constant
      #
      # The reason why code actions were requested.
      #
      module CodeActionTriggerKind
        #
        # Code actions were explicitly requested by the user or by an extension.
        #
        INVOKED = 1
        #
        # Code actions were requested automatically.
        #
        # This typically happens when current selection in a file changes, but can
        # also be triggered when file content changes.
        #
        AUTOMATIC = 2
      end
    end
  end
end
