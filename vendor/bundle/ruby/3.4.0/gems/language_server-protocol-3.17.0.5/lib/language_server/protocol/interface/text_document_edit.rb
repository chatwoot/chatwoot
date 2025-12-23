module LanguageServer
  module Protocol
    module Interface
      class TextDocumentEdit
        def initialize(text_document:, edits:)
          @attributes = {}

          @attributes[:textDocument] = text_document
          @attributes[:edits] = edits

          @attributes.freeze
        end

        #
        # The text document to change.
        #
        # @return [OptionalVersionedTextDocumentIdentifier]
        def text_document
          attributes.fetch(:textDocument)
        end

        #
        # The edits to be applied.
        #
        # @return [(TextEdit | AnnotatedTextEdit)[]]
        def edits
          attributes.fetch(:edits)
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
