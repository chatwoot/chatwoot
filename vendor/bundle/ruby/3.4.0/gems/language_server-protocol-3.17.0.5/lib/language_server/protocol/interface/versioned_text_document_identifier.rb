module LanguageServer
  module Protocol
    module Interface
      class VersionedTextDocumentIdentifier
        def initialize(uri:, version:)
          @attributes = {}

          @attributes[:uri] = uri
          @attributes[:version] = version

          @attributes.freeze
        end

        #
        # The text document's URI.
        #
        # @return [string]
        def uri
          attributes.fetch(:uri)
        end

        #
        # The version number of this document.
        #
        # The version number of a document will increase after each change,
        # including undo/redo. The number doesn't need to be consecutive.
        #
        # @return [number]
        def version
          attributes.fetch(:version)
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
