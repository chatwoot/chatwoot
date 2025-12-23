module LanguageServer
  module Protocol
    module Interface
      #
      # The parameters sent in notifications/requests for user-initiated deletes
      # of files.
      #
      class DeleteFilesParams
        def initialize(files:)
          @attributes = {}

          @attributes[:files] = files

          @attributes.freeze
        end

        #
        # An array of all files/folders deleted in this operation.
        #
        # @return [FileDelete[]]
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
