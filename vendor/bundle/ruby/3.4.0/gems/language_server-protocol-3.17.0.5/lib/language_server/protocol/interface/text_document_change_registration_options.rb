module LanguageServer
  module Protocol
    module Interface
      #
      # Describe options to be used when registering for text document change events.
      #
      class TextDocumentChangeRegistrationOptions
        def initialize(document_selector:, sync_kind:)
          @attributes = {}

          @attributes[:documentSelector] = document_selector
          @attributes[:syncKind] = sync_kind

          @attributes.freeze
        end

        #
        # A document selector to identify the scope of the registration. If set to
        # null the document selector provided on the client side will be used.
        #
        # @return [DocumentSelector]
        def document_selector
          attributes.fetch(:documentSelector)
        end

        #
        # How documents are synced to the server. See TextDocumentSyncKind.Full
        # and TextDocumentSyncKind.Incremental.
        #
        # @return [TextDocumentSyncKind]
        def sync_kind
          attributes.fetch(:syncKind)
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
