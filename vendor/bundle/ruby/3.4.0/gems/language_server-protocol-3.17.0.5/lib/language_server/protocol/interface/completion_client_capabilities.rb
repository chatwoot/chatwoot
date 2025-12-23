module LanguageServer
  module Protocol
    module Interface
      class CompletionClientCapabilities
        def initialize(dynamic_registration: nil, completion_item: nil, completion_item_kind: nil, context_support: nil, insert_text_mode: nil, completion_list: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:completionItem] = completion_item if completion_item
          @attributes[:completionItemKind] = completion_item_kind if completion_item_kind
          @attributes[:contextSupport] = context_support if context_support
          @attributes[:insertTextMode] = insert_text_mode if insert_text_mode
          @attributes[:completionList] = completion_list if completion_list

          @attributes.freeze
        end

        #
        # Whether completion supports dynamic registration.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # The client supports the following `CompletionItem` specific
        # capabilities.
        #
        # @return [{ snippetSupport?: boolean; commitCharactersSupport?: boolean; documentationFormat?: MarkupKind[]; deprecatedSupport?: boolean; preselectSupport?: boolean; tagSupport?: { valueSet: 1[]; }; insertReplaceSupport?: boolean; resolveSupport?: { ...; }; insertTextModeSupport?: { ...; }; labelDetailsSupport?: boolean; }]
        def completion_item
          attributes.fetch(:completionItem)
        end

        # @return [{ valueSet?: CompletionItemKind[]; }]
        def completion_item_kind
          attributes.fetch(:completionItemKind)
        end

        #
        # The client supports to send additional context information for a
        # `textDocument/completion` request.
        #
        # @return [boolean]
        def context_support
          attributes.fetch(:contextSupport)
        end

        #
        # The client's default when the completion item doesn't provide a
        # `insertTextMode` property.
        #
        # @return [InsertTextMode]
        def insert_text_mode
          attributes.fetch(:insertTextMode)
        end

        #
        # The client supports the following `CompletionList` specific
        # capabilities.
        #
        # @return [{ itemDefaults?: string[]; }]
        def completion_list
          attributes.fetch(:completionList)
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
