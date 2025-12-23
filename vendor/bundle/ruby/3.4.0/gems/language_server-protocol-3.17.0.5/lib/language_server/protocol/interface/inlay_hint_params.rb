module LanguageServer
  module Protocol
    module Interface
      #
      # A parameter literal used in inlay hint requests.
      #
      class InlayHintParams
        def initialize(work_done_token: nil, text_document:, range:)
          @attributes = {}

          @attributes[:workDoneToken] = work_done_token if work_done_token
          @attributes[:textDocument] = text_document
          @attributes[:range] = range

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
        # The visible document range for which inlay hints should be computed.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
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
