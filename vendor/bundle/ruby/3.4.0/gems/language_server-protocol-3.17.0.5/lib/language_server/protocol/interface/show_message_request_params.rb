module LanguageServer
  module Protocol
    module Interface
      class ShowMessageRequestParams
        def initialize(type:, message:, actions: nil)
          @attributes = {}

          @attributes[:type] = type
          @attributes[:message] = message
          @attributes[:actions] = actions if actions

          @attributes.freeze
        end

        #
        # The message type. See {@link MessageType}
        #
        # @return [MessageType]
        def type
          attributes.fetch(:type)
        end

        #
        # The actual message
        #
        # @return [string]
        def message
          attributes.fetch(:message)
        end

        #
        # The message action items to present.
        #
        # @return [MessageActionItem[]]
        def actions
          attributes.fetch(:actions)
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
