module LanguageServer
  module Protocol
    module Constant
      #
      # Completion item tags are extra annotations that tweak the rendering of a
      # completion item.
      #
      module CompletionItemTag
        #
        # Render a completion as obsolete, usually using a strike-out.
        #
        DEPRECATED = 1
      end
    end
  end
end
