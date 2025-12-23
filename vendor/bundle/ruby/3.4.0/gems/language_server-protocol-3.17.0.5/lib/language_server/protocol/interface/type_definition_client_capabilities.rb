module LanguageServer
  module Protocol
    module Interface
      class TypeDefinitionClientCapabilities
        def initialize(dynamic_registration: nil, link_support: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:linkSupport] = link_support if link_support

          @attributes.freeze
        end

        #
        # Whether implementation supports dynamic registration. If this is set to
        # `true` the client supports the new `TypeDefinitionRegistrationOptions`
        # return value for the corresponding server capability as well.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # The client supports additional metadata in the form of definition links.
        #
        # @return [boolean]
        def link_support
          attributes.fetch(:linkSupport)
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
