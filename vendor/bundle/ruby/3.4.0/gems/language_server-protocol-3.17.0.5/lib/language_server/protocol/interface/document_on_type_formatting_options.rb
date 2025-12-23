module LanguageServer
  module Protocol
    module Interface
      class DocumentOnTypeFormattingOptions
        def initialize(first_trigger_character:, more_trigger_character: nil)
          @attributes = {}

          @attributes[:firstTriggerCharacter] = first_trigger_character
          @attributes[:moreTriggerCharacter] = more_trigger_character if more_trigger_character

          @attributes.freeze
        end

        #
        # A character on which formatting should be triggered, like `{`.
        #
        # @return [string]
        def first_trigger_character
          attributes.fetch(:firstTriggerCharacter)
        end

        #
        # More trigger characters.
        #
        # @return [string[]]
        def more_trigger_character
          attributes.fetch(:moreTriggerCharacter)
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
