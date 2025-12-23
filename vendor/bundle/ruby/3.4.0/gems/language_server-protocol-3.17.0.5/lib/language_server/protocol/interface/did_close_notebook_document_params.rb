module LanguageServer
  module Protocol
    module Interface
      #
      # The params sent in a close notebook document notification.
      #
      class DidCloseNotebookDocumentParams
        def initialize(notebook_document:, cell_text_documents:)
          @attributes = {}

          @attributes[:notebookDocument] = notebook_document
          @attributes[:cellTextDocuments] = cell_text_documents

          @attributes.freeze
        end

        #
        # The notebook document that got closed.
        #
        # @return [NotebookDocumentIdentifier]
        def notebook_document
          attributes.fetch(:notebookDocument)
        end

        #
        # The text documents that represent the content
        # of a notebook cell that got closed.
        #
        # @return [TextDocumentIdentifier[]]
        def cell_text_documents
          attributes.fetch(:cellTextDocuments)
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
