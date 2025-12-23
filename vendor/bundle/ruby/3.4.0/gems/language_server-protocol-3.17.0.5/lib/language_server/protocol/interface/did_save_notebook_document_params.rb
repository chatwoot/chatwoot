module LanguageServer
  module Protocol
    module Interface
      #
      # The params sent in a save notebook document notification.
      #
      class DidSaveNotebookDocumentParams
        def initialize(notebook_document:)
          @attributes = {}

          @attributes[:notebookDocument] = notebook_document

          @attributes.freeze
        end

        #
        # The notebook document that got saved.
        #
        # @return [NotebookDocumentIdentifier]
        def notebook_document
          attributes.fetch(:notebookDocument)
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
