module LanguageServer
  module Protocol
    module Interface
      class WorkspaceSymbolClientCapabilities
        def initialize(dynamic_registration: nil, symbol_kind: nil, tag_support: nil, resolve_support: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:symbolKind] = symbol_kind if symbol_kind
          @attributes[:tagSupport] = tag_support if tag_support
          @attributes[:resolveSupport] = resolve_support if resolve_support

          @attributes.freeze
        end

        #
        # Symbol request supports dynamic registration.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # Specific capabilities for the `SymbolKind` in the `workspace/symbol`
        # request.
        #
        # @return [{ valueSet?: SymbolKind[]; }]
        def symbol_kind
          attributes.fetch(:symbolKind)
        end

        #
        # The client supports tags on `SymbolInformation` and `WorkspaceSymbol`.
        # Clients supporting tags have to handle unknown tags gracefully.
        #
        # @return [{ valueSet: 1[]; }]
        def tag_support
          attributes.fetch(:tagSupport)
        end

        #
        # The client support partial workspace symbols. The client will send the
        # request `workspaceSymbol/resolve` to the server to resolve additional
        # properties.
        #
        # @return [{ properties: string[]; }]
        def resolve_support
          attributes.fetch(:resolveSupport)
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
