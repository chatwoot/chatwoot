module LanguageServer
  module Protocol
    module Interface
      #
      # Client capabilities specific to diagnostic pull requests.
      #
      class DiagnosticClientCapabilities
        def initialize(dynamic_registration: nil, related_document_support: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:relatedDocumentSupport] = related_document_support if related_document_support

          @attributes.freeze
        end

        #
        # Whether implementation supports dynamic registration. If this is set to
        # `true` the client supports the new
        # `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
        # return value for the corresponding server capability as well.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # Whether the clients supports related documents for document diagnostic
        # pulls.
        #
        # @return [boolean]
        def related_document_support
          attributes.fetch(:relatedDocumentSupport)
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
