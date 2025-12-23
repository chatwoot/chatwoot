module LanguageServer
  module Protocol
    module Interface
      #
      # Params for the CodeActionRequest
      #
      class CodeActionParams
        def initialize(work_done_token: nil, partial_result_token: nil, text_document:, range:, context:)
          @attributes = {}

          @attributes[:workDoneToken] = work_done_token if work_done_token
          @attributes[:partialResultToken] = partial_result_token if partial_result_token
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
        # An optional token that a server can use to report partial results (e.g.
        # streaming) to the client.
        #
        # @return [ProgressToken]
        def partial_result_token
          attributes.fetch(:partialResultToken)
        end

        #
        # The document in which the command was invoked.
        #
        # @return [TextDocumentIdentifier]
        def text_document
          attributes.fetch(:textDocument)
        end

        #
        # The range for which the command was invoked.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
        end

        #
        # Context carrying additional information.
        #
        # @return [CodeActionContext]
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
