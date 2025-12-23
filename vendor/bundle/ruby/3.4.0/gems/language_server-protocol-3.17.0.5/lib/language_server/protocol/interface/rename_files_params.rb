module LanguageServer
  module Protocol
    module Interface
      #
      # The parameters sent in notifications/requests for user-initiated renames
      # of files.
      #
      class RenameFilesParams
        def initialize(files:)
          @attributes = {}

          @attributes[:files] = files

          @attributes.freeze
        end

        #
        # An array of all files/folders renamed in this operation. When a folder
        # is renamed, only the folder will be included, and not its children.
        #
        # @return [FileRename[]]
        def files
          attributes.fetch(:files)
        end

        attr_reader :attributes

        def to_hash
          attributes
        end

        def to_json(*args)
          to_hash.to_json(*args)
        end
      end
    end
  end
end
