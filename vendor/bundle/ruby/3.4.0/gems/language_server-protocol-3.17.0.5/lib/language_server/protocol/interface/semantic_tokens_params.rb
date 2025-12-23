module LanguageServer
  module Protocol
    module Interface
      class SemanticTokensParams
        def initialize(work_done_token: nil, partial_result_token: nil, text_document:)
          @attributes = {}

          @attributes[:workDoneToken] = work_done_token if work_done_token
          @attributes[:partialResultToken] = partial_result_token if partial_result_token
          @attributes[:textDocument] = text_document

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
        # An optional token that a server can use to report partial results (e.g.
        # streaming) to the client.
        #
        # @return [ProgressToken]
        def partial_result_token
          attributes.fetch(:partialResultToken)
        end

        #
        # The text document.
        #
        # @return [TextDocumentIdentifier]
        def text_document
          attributes.fetch(:textDocument)
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
