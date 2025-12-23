module LanguageServer
  module Protocol
    module Interface
      #
      # Represents information on a file/folder rename.
      #
      class FileRename
        def initialize(old_uri:, new_uri:)
          @attributes = {}

          @attributes[:oldUri] = old_uri
          @attributes[:newUri] = new_uri

          @attributes.freeze
        end

        #
        # A file:// URI for the original location of the file/folder being renamed.
        #
        # @return [string]
        def old_uri
          attributes.fetch(:oldUri)
        end

        #
        # A file:// URI for the new location of the file/folder being renamed.
        #
        # @return [string]
        def new_uri
          attributes.fetch(:newUri)
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
