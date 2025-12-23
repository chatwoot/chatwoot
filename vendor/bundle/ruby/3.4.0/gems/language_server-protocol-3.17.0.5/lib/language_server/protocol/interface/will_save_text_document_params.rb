module LanguageServer
  module Protocol
    module Interface
      #
      # The parameters send in a will save text document notification.
      #
      class WillSaveTextDocumentParams
        def initialize(text_document:, reason:)
          @attributes = {}

          @attributes[:textDocument] = text_document
          @attributes[:reason] = reason

          @attributes.freeze
        end

        #
        # The document that will be saved.
        #
        # @return [TextDocumentIdentifier]
        def text_document
          attributes.fetch(:textDocument)
        end

        #
        # The 'TextDocumentSaveReason'.
        #
        # @return [TextDocumentSaveReason]
        def reason
          attributes.fetch(:reason)
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
