module LanguageServer
  module Protocol
    module Interface
      #
      # Additional information about the context in which a signature help request
      # was triggered.
      #
      class SignatureHelpContext
        def initialize(trigger_kind:, trigger_character: nil, is_retrigger:, active_signature_help: nil)
          @attributes = {}

          @attributes[:triggerKind] = trigger_kind
          @attributes[:triggerCharacter] = trigger_character if trigger_character
          @attributes[:isRetrigger] = is_retrigger
          @attributes[:activeSignatureHelp] = active_signature_help if active_signature_help

          @attributes.freeze
        end

        #
        # Action that caused signature help to be triggered.
        #
        # @return [SignatureHelpTriggerKind]
        def trigger_kind
          attributes.fetch(:triggerKind)
        end

        #
        # Character that caused signature help to be triggered.
        #
        # This is undefined when triggerKind !==
        # SignatureHelpTriggerKind.TriggerCharacter
        #
        # @return [string]
        def trigger_character
          attributes.fetch(:triggerCharacter)
        end

        #
        # `true` if signature help was already showing when it was triggered.
        #
        # Retriggers occur when the signature help is already active and can be
        # caused by actions such as typing a trigger character, a cursor move, or
        # document content changes.
        #
        # @return [boolean]
        def is_retrigger
          attributes.fetch(:isRetrigger)
        end

        #
        # The currently active `SignatureHelp`.
        #
        # The `activeSignatureHelp` has its `SignatureHelp.activeSignature` field
        # updated based on the user navigating through available signatures.
        #
        # @return [SignatureHelp]
        def active_signature_help
          attributes.fetch(:activeSignatureHelp)
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
