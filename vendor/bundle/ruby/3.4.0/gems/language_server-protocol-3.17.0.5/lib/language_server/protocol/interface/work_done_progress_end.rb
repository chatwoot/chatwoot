module LanguageServer
  module Protocol
    module Interface
      class WorkDoneProgressEnd
        def initialize(kind:, message: nil)
          @attributes = {}

          @attributes[:kind] = kind
          @attributes[:message] = message if message

          @attributes.freeze
        end

        # @return ["end"]
        def kind
          attributes.fetch(:kind)
        end

        #
        # Optional, a final message indicating to for example indicate the outcome
        # of the operation.
        #
        # @return [string]
        def message
          attributes.fetch(:message)
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
