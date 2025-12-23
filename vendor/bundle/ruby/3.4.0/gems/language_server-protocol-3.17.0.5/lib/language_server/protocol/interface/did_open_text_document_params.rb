module LanguageServer
  module Protocol
    module Interface
      class DidOpenTextDocumentParams
        def initialize(text_document:)
          @attributes = {}

          @attributes[:textDocument] = text_document

          @attributes.freeze
        end

        #
        # The document that was opened.
        #
        # @return [TextDocumentItem]
        def text_document
          attributes.fetch(:textDocument)
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
