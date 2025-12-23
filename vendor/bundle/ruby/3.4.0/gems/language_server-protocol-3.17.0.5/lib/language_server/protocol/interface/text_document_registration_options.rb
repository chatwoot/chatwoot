module LanguageServer
  module Protocol
    module Interface
      #
      # General text document registration options.
      #
      class TextDocumentRegistrationOptions
        def initialize(document_selector:)
          @attributes = {}

          @attributes[:documentSelector] = document_selector

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
