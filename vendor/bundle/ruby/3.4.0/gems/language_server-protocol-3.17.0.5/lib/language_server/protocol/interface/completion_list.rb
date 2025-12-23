module LanguageServer
  module Protocol
    module Interface
      #
      # Represents a collection of [completion items](#CompletionItem) to be
      # presented in the editor.
      #
      class CompletionList
        def initialize(is_incomplete:, item_defaults: nil, items:)
          @attributes = {}

          @attributes[:isIncomplete] = is_incomplete
          @attributes[:itemDefaults] = item_defaults if item_defaults
          @attributes[:items] = items

          @attributes.freeze
        end

        #
        # This list is not complete. Further typing should result in recomputing
        # this list.
        #
        # Recomputed lists have all their items replaced (not appended) in the
        # incomplete completion sessions.
        #
        # @return [boolean]
        def is_incomplete
          attributes.fetch(:isIncomplete)
        end

        #
        # In many cases the items of an actual completion result share the same
        # value for properties like `commitCharacters` or the range of a text
        # edit. A completion list can therefore define item defaults which will
        # be used if a completion item itself doesn't specify the value.
        #
        # If a completion list specifies a default value and a completion item
        # also specifies a corresponding value the one from the item is used.
        #
        # Servers are only allowed to return default values if the client
        # signals support for this via the `completionList.itemDefaults`
        # capability.
        #
        # @return [{ commitCharacters?: string[]; editRange?: Range | { insert: Range; replace: Range; }; insertTextFormat?: InsertTextFormat; insertTextMode?: InsertTextMode; data?: LSPAny; }]
        def item_defaults
          attributes.fetch(:itemDefaults)
        end

        #
        # The completion items.
        #
        # @return [CompletionItem[]]
        def items
          attributes.fetch(:items)
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
