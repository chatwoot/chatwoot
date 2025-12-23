module LanguageServer
  module Protocol
    module Interface
      #
      # Options specific to a notebook plus its cells
      # to be synced to the server.
      #
      # If a selector provides a notebook document
      # filter but no cell selector all cells of a
      # matching notebook document will be synced.
      #
      # If a selector provides no notebook document
      # filter but only a cell selector all notebook
      # documents that contain at least one matching
      # cell will be synced.
      #
      class NotebookDocumentSyncOptions
        def initialize(notebook_selector:, save: nil)
          @attributes = {}

          @attributes[:notebookSelector] = notebook_selector
          @attributes[:save] = save if save

          @attributes.freeze
        end

        #
        # The notebooks to be synced
        #
        # @return [({ notebook: string | NotebookDocumentFilter; cells?: { language: string; }[]; } | { notebook?: string | NotebookDocumentFilter; cells: { ...; }[]; })[]]
        def notebook_selector
          attributes.fetch(:notebookSelector)
        end

        #
        # Whether save notification should be forwarded to
        # the server. Will only be honored if mode === `notebook`.
        #
        # @return [boolean]
        def save
          attributes.fetch(:save)
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
