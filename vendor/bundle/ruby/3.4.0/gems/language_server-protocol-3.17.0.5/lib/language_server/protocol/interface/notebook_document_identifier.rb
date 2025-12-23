module LanguageServer
  module Protocol
    module Interface
      #
      # A literal to identify a notebook document in the client.
      #
      class NotebookDocumentIdentifier
        def initialize(uri:)
          @attributes = {}

          @attributes[:uri] = uri

          @attributes.freeze
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
