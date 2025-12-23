module LanguageServer
  module Protocol
    module Interface
      class SignatureHelpClientCapabilities
        def initialize(dynamic_registration: nil, signature_information: nil, context_support: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:signatureInformation] = signature_information if signature_information
          @attributes[:contextSupport] = context_support if context_support

          @attributes.freeze
        end

        #
        # Whether signature help supports dynamic registration.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # The client supports the following `SignatureInformation`
        # specific properties.
        #
        # @return [{ documentationFormat?: MarkupKind[]; parameterInformation?: { labelOffsetSupport?: boolean; }; activeParameterSupport?: boolean; }]
        def signature_information
          attributes.fetch(:signatureInformation)
        end

        #
        # The client supports to send additional context information for a
        # `textDocument/signatureHelp` request. A client that opts into
        # contextSupport will also support the `retriggerCharacters` on
        # `SignatureHelpOptions`.
        #
        # @return [boolean]
        def context_support
          attributes.fetch(:contextSupport)
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
