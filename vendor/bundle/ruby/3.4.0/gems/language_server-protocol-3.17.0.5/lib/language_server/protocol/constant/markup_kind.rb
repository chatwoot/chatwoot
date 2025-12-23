module LanguageServer
  module Protocol
    module Constant
      #
      # Describes the content type that a client supports in various
      # result literals like `Hover`, `ParameterInfo` or `CompletionItem`.
      #
      # Please note that `MarkupKinds` must not start with a `$`. This kinds
      # are reserved for internal usage.
      #
      module MarkupKind
        #
        # Plain text is supported as a content format
        #
        PLAIN_TEXT = 'plaintext'
        #
        # Markdown is supported as a content format
        #
        MARKDOWN = 'markdown'
      end
    end
  end
end
