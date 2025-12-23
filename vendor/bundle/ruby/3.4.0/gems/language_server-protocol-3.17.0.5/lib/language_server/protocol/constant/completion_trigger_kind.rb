module LanguageServer
  module Protocol
    module Constant
      #
      # How a completion was triggered
      #
      module CompletionTriggerKind
        #
        # Completion was triggered by typing an identifier (24x7 code
        # complete), manual invocation (e.g Ctrl+Space) or via API.
        #
        INVOKED = 1
        #
        # Completion was triggered by a trigger character specified by
        # the `triggerCharacters` properties of the
        # `CompletionRegistrationOptions`.
        #
        TRIGGER_CHARACTER = 2
        #
        # Completion was re-triggered as the current completion list is incomplete.
        #
        TRIGGER_FOR_INCOMPLETE_COMPLETIONS = 3
      end
    end
  end
end
