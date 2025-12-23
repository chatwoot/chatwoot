module LanguageServer
  module Protocol
    module Constant
      #
      # The kind of resource operations supported by the client.
      #
      module ResourceOperationKind
        #
        # Supports creating new files and folders.
        #
        CREATE = 'create'
        #
        # Supports renaming existing files and folders.
        #
        RENAME = 'rename'
        #
        # Supports deleting existing files and folders.
        #
        DELETE = 'delete'
      end
    end
  end
end
