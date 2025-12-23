module LanguageServer
  module Protocol
    module Interface
      class TextDocumentIdentifier
        def initialize(uri:)
          @attributes = {}

          @attributes[:uri] = uri

          @attributes.freeze
        end

        #
        # The text document's URI.
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
