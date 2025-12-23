module LanguageServer
  module Protocol
    module Interface
      #
      # The params sent in a change notebook document notification.
      #
      class DidChangeNotebookDocumentParams
        def initialize(notebook_document:, change:)
          @attributes = {}

          @attributes[:notebookDocument] = notebook_document
          @attributes[:change] = change

          @attributes.freeze
        end

        #
        # The notebook document that did change. The version number points
        # to the version after all provided changes have been applied.
        #
        # @return [VersionedNotebookDocumentIdentifier]
        def notebook_document
          attributes.fetch(:notebookDocument)
        end

        #
        # The actual changes to the notebook document.
        #
        # The change describes single state change to the notebook document.
        # So it moves a notebook document, its cells and its cell text document
        # contents from state S to S'.
        #
        # To mirror the content of a notebook using change events use the
        # following approach:
        # - start with the same initial content
        # - apply the 'notebookDocument/didChange' notifications in the order
        # you receive them.
        #
        # @return [NotebookDocumentChangeEvent]
        def change
          attributes.fetch(:change)
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
