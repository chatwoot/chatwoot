module LanguageServer
  module Protocol
    module Interface
      #
      # A notebook cell text document filter denotes a cell text
      # document by different properties.
      #
      class NotebookCellTextDocumentFilter
        def initialize(notebook:, language: nil)
          @attributes = {}

          @attributes[:notebook] = notebook
          @attributes[:language] = language if language

          @attributes.freeze
        end

        #
        # A filter that matches against the notebook
        # containing the notebook cell. If a string
        # value is provided it matches against the
        # notebook type. '*' matches every notebook.
        #
        # @return [string | NotebookDocumentFilter]
        def notebook
          attributes.fetch(:notebook)
        end

        #
        # A language id like `python`.
        #
        # Will be matched against the language id of the
        # notebook cell document. '*' matches every language.
        #
        # @return [string]
        def language
          attributes.fetch(:language)
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
