module LanguageServer
  module Protocol
    module Interface
      #
      # Contains additional diagnostic information about the context in which
      # a code action is run.
      #
      class CodeActionContext
        def initialize(diagnostics:, only: nil, trigger_kind: nil)
          @attributes = {}

          @attributes[:diagnostics] = diagnostics
          @attributes[:only] = only if only
          @attributes[:triggerKind] = trigger_kind if trigger_kind

          @attributes.freeze
        end

        #
        # An array of diagnostics known on the client side overlapping the range
        # provided to the `textDocument/codeAction` request. They are provided so
        # that the server knows which errors are currently presented to the user
        # for the given range. There is no guarantee that these accurately reflect
        # the error state of the resource. The primary parameter
        # to compute code actions is the provided range.
        #
        # @return [Diagnostic[]]
        def diagnostics
          attributes.fetch(:diagnostics)
        end

        #
        # Requested kind of actions to return.
        #
        # Actions not of this kind are filtered out by the client before being
        # shown. So servers can omit computing them.
        #
        # @return [string[]]
        def only
          attributes.fetch(:only)
        end

        #
        # The reason why code actions were requested.
        #
        # @return [CodeActionTriggerKind]
        def trigger_kind
          attributes.fetch(:triggerKind)
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
