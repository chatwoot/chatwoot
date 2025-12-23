module LanguageServer
  module Protocol
    module Interface
      #
      # Show message request client capabilities
      #
      class ShowMessageRequestClientCapabilities
        def initialize(message_action_item: nil)
          @attributes = {}

          @attributes[:messageActionItem] = message_action_item if message_action_item

          @attributes.freeze
        end

        #
        # Capabilities specific to the `MessageActionItem` type.
        #
        # @return [{ additionalPropertiesSupport?: boolean; }]
        def message_action_item
          attributes.fetch(:messageActionItem)
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
