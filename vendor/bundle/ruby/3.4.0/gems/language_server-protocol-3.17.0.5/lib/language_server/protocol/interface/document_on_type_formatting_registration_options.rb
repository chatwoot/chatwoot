module LanguageServer
  module Protocol
    module Interface
      class DocumentOnTypeFormattingRegistrationOptions
        def initialize(document_selector:, first_trigger_character:, more_trigger_character: nil)
          @attributes = {}

          @attributes[:documentSelector] = document_selector
          @attributes[:firstTriggerCharacter] = first_trigger_character
          @attributes[:moreTriggerCharacter] = more_trigger_character if more_trigger_character

          @attributes.freeze
        end

        #
        # A document selector to identify the scope of the registration. If set to
        # null the document selector provided on the client side will be used.
        #
        # @return [DocumentSelector]
        def document_selector
          attributes.fetch(:documentSelector)
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
