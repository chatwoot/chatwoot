module LanguageServer
  module Protocol
    module Interface
      #
      # A notebook cell.
      #
      # A cell's document URI must be unique across ALL notebook
      # cells and can therefore be used to uniquely identify a
      # notebook cell or the cell's text document.
      #
      class NotebookCell
        def initialize(kind:, document:, metadata: nil, execution_summary: nil)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:document] = document
          @attributes[:metadata] = metadata if metadata
          @attributes[:executionSummary] = execution_summary if execution_summary

          @attributes.freeze
        end

        #
        # The cell's kind
        #
        # @return [any]
        def kind
          attributes.fetch(:kind)
        end

        #
        # The URI of the cell's text document
        # content.
        #
        # @return [string]
        def document
          attributes.fetch(:document)
        end

        #
        # Additional metadata stored with the cell.
        #
        # @return [LSPObject]
        def metadata
          attributes.fetch(:metadata)
        end

        #
        # Additional execution summary information
        # if supported by the client.
        #
        # @return [ExecutionSummary]
        def execution_summary
          attributes.fetch(:executionSummary)
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
