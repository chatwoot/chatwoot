module LanguageServer
  module Protocol
    module Interface
      class TextDocumentSaveRegistrationOptions
        def initialize(document_selector:, include_text: nil)
          @attributes = {}

          @attributes[:documentSelector] = document_selector
          @attributes[:includeText] = include_text if include_text

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
        # The client is supposed to include the content on save.
        #
        # @return [boolean]
        def include_text
          attributes.fetch(:includeText)
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
