module LanguageServer
  module Protocol
    module Interface
      class HoverClientCapabilities
        def initialize(dynamic_registration: nil, content_format: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:contentFormat] = content_format if content_format

          @attributes.freeze
        end

        #
        # Whether hover supports dynamic registration.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # Client supports the follow content formats if the content
        # property refers to a `literal of type MarkupContent`.
        # The order describes the preferred format of the client.
        #
        # @return [MarkupKind[]]
        def content_format
          attributes.fetch(:contentFormat)
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
