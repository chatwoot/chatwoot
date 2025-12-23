module LanguageServer
  module Protocol
    module Interface
      class CodeActionRegistrationOptions
        def initialize(document_selector:, work_done_progress: nil, code_action_kinds: nil, resolve_provider: nil)
          @attributes = {}

          @attributes[:documentSelector] = document_selector
          @attributes[:workDoneProgress] = work_done_progress if work_done_progress
          @attributes[:codeActionKinds] = code_action_kinds if code_action_kinds
          @attributes[:resolveProvider] = resolve_provider if resolve_provider

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

        # @return [boolean]
        def work_done_progress
          attributes.fetch(:workDoneProgress)
        end

        #
        # CodeActionKinds that this server may return.
        #
        # The list of kinds may be generic, such as `CodeActionKind.Refactor`,
        # or the server may list out every specific kind they provide.
        #
        # @return [string[]]
        def code_action_kinds
          attributes.fetch(:codeActionKinds)
        end

        #
        # The server provides support to resolve additional
        # information for a code action.
        #
        # @return [boolean]
        def resolve_provider
          attributes.fetch(:resolveProvider)
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
