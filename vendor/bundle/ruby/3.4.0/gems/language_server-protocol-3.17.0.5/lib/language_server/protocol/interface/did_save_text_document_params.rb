module LanguageServer
  module Protocol
    module Interface
      class DidSaveTextDocumentParams
        def initialize(text_document:, text: nil)
          @attributes = {}

          @attributes[:textDocument] = text_document
          @attributes[:text] = text if text

          @attributes.freeze
        end

        #
        # The document that was saved.
        #
        # @return [TextDocumentIdentifier]
        def text_document
          attributes.fetch(:textDocument)
        end

        #
        # Optional the content when saved. Depends on the includeText value
        # when the save notification was requested.
        #
        # @return [string]
        def text
          attributes.fetch(:text)
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
