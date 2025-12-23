module LanguageServer
  module Protocol
    module Interface
      #
      # A parameter literal used in inline value requests.
      #
      class InlineValueParams
        def initialize(work_done_token: nil, text_document:, range:, context:)
          @attributes = {}

          @attributes[:workDoneToken] = work_done_token if work_done_token
          @attributes[:textDocument] = text_document
          @attributes[:range] = range
          @attributes[:context] = context

          @attributes.freeze
        end

        #
        # An optional token that a server can use to report work done progress.
        #
        # @return [ProgressToken]
        def work_done_token
          attributes.fetch(:workDoneToken)
        end

        #
        # The text document.
        #
        # @return [TextDocumentIdentifier]
        def text_document
          attributes.fetch(:textDocument)
        end

        #
        # The document range for which inline values should be computed.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
        end

        #
        # Additional information about the context in which inline values were
        # requested.
        #
        # @return [InlineValueContext]
        def context
          attributes.fetch(:context)
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
