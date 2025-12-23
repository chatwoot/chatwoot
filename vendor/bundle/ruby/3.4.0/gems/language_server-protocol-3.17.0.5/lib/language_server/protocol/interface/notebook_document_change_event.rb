module LanguageServer
  module Protocol
    module Interface
      #
      # A change event for a notebook document.
      #
      class NotebookDocumentChangeEvent
        def initialize(metadata: nil, cells: nil)
          @attributes = {}

          @attributes[:metadata] = metadata if metadata
          @attributes[:cells] = cells if cells

          @attributes.freeze
        end

        #
        # The changed meta data if any.
        #
        # @return [LSPObject]
        def metadata
          attributes.fetch(:metadata)
        end

        #
        # Changes to cells
        #
        # @return [{ structure?: { array: NotebookCellArrayChange; didOpen?: TextDocumentItem[]; didClose?: TextDocumentIdentifier[]; }; data?: NotebookCell[]; textContent?: { ...; }[]; }]
        def cells
          attributes.fetch(:cells)
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
