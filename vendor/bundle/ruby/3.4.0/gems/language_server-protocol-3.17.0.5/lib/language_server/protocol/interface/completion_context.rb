module LanguageServer
  module Protocol
    module Interface
      #
      # Contains additional information about the context in which a completion
      # request is triggered.
      #
      class CompletionContext
        def initialize(trigger_kind:, trigger_character: nil)
          @attributes = {}

          @attributes[:triggerKind] = trigger_kind
          @attributes[:triggerCharacter] = trigger_character if trigger_character

          @attributes.freeze
        end

        #
        # How the completion was triggered.
        #
        # @return [CompletionTriggerKind]
        def trigger_kind
          attributes.fetch(:triggerKind)
        end

        #
        # The trigger character (a single character) that has trigger code
        # complete. Is undefined if
        # `triggerKind !== CompletionTriggerKind.TriggerCharacter`
        #
        # @return [string]
        def trigger_character
          attributes.fetch(:triggerCharacter)
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
