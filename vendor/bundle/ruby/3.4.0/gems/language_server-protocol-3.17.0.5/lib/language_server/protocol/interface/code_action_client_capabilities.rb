module LanguageServer
  module Protocol
    module Interface
      class CodeActionClientCapabilities
        def initialize(dynamic_registration: nil, code_action_literal_support: nil, is_preferred_support: nil, disabled_support: nil, data_support: nil, resolve_support: nil, honors_change_annotations: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:codeActionLiteralSupport] = code_action_literal_support if code_action_literal_support
          @attributes[:isPreferredSupport] = is_preferred_support if is_preferred_support
          @attributes[:disabledSupport] = disabled_support if disabled_support
          @attributes[:dataSupport] = data_support if data_support
          @attributes[:resolveSupport] = resolve_support if resolve_support
          @attributes[:honorsChangeAnnotations] = honors_change_annotations if honors_change_annotations

          @attributes.freeze
        end

        #
        # Whether code action supports dynamic registration.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # The client supports code action literals as a valid
        # response of the `textDocument/codeAction` request.
        #
        # @return [{ codeActionKind: { valueSet: string[]; }; }]
        def code_action_literal_support
          attributes.fetch(:codeActionLiteralSupport)
        end

        #
        # Whether code action supports the `isPreferred` property.
        #
        # @return [boolean]
        def is_preferred_support
          attributes.fetch(:isPreferredSupport)
        end

        #
        # Whether code action supports the `disabled` property.
        #
        # @return [boolean]
        def disabled_support
          attributes.fetch(:disabledSupport)
        end

        #
        # Whether code action supports the `data` property which is
        # preserved between a `textDocument/codeAction` and a
        # `codeAction/resolve` request.
        #
        # @return [boolean]
        def data_support
          attributes.fetch(:dataSupport)
        end

        #
        # Whether the client supports resolving additional code action
        # properties via a separate `codeAction/resolve` request.
        #
        # @return [{ properties: string[]; }]
        def resolve_support
          attributes.fetch(:resolveSupport)
        end

        #
        # Whether the client honors the change annotations in
        # text edits and resource operations returned via the
        # `CodeAction#edit` property by for example presenting
        # the workspace edit in the user interface and asking
        # for confirmation.
        #
        # @return [boolean]
        def honors_change_annotations
          attributes.fetch(:honorsChangeAnnotations)
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
