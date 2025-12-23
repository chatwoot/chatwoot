module LanguageServer
  module Protocol
    module Constant
      #
      # The file event type.
      #
      module FileChangeType
        #
        # The file got created.
        #
        CREATED = 1
        #
        # The file got changed.
        #
        CHANGED = 2
        #
        # The file got deleted.
        #
        DELETED = 3
      end
    end
  end
end
