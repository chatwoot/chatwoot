module LanguageServer
  module Protocol
    module Interface
      class SignatureHelpParams
        def initialize(text_document:, position:, work_done_token: nil, context: nil)
          @attributes = {}

          @attributes[:textDocument] = text_document
          @attributes[:position] = position
          @attributes[:workDoneToken] = work_done_token if work_done_token
          @attributes[:context] = context if context

          @attributes.freeze
        end

        #
        # The text document.
        #
        # @return [TextDocumentIdentifier]
        def text_document
          attributes.fetch(:textDocument)
        end

        #
        # The position inside the text document.
        #
        # @return [Position]
        def position
          attributes.fetch(:position)
        end

        #
        # An optional token that a server can use to report work done progress.
        #
        # @return [ProgressToken]
        def work_done_token
          attributes.fetch(:workDoneToken)
        end

        #
        # The signature help context. This is only available if the client
        # specifies to send this using the client capability
        # `textDocument.signatureHelp.contextSupport === true`
        #
        # @return [SignatureHelpContext]
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
