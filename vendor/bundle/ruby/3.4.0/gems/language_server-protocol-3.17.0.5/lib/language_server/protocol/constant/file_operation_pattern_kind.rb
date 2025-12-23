module LanguageServer
  module Protocol
    module Constant
      #
      # A pattern kind describing if a glob pattern matches a file a folder or
      # both.
      #
      module FileOperationPatternKind
        #
        # The pattern matches a file only.
        #
        FILE = 'file'
        #
        # The pattern matches a folder only.
        #
        FOLDER = 'folder'
      end
    end
  end
end
