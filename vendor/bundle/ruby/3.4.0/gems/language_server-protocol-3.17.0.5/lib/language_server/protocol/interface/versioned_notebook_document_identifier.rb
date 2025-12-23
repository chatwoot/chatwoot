module LanguageServer
  module Protocol
    module Interface
      #
      # A versioned notebook document identifier.
      #
      class VersionedNotebookDocumentIdentifier
        def initialize(version:, uri:)
          @attributes = {}

          @attributes[:version] = version
          @attributes[:uri] = uri

          @attributes.freeze
        end

        #
        # The version number of this notebook document.
        #
        # @return [number]
        def version
          attributes.fetch(:version)
        end

        #
        # The notebook document's URI.
        #
        # @return [string]
        def uri
          attributes.fetch(:uri)
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
