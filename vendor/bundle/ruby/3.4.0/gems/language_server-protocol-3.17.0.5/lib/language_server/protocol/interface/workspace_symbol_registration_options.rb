module LanguageServer
  module Protocol
    module Interface
      class WorkspaceSymbolRegistrationOptions
        def initialize(work_done_progress: nil, resolve_provider: nil)
          @attributes = {}

          @attributes[:workDoneProgress] = work_done_progress if work_done_progress
          @attributes[:resolveProvider] = resolve_provider if resolve_provider

          @attributes.freeze
        end

        # @return [boolean]
        def work_done_progress
          attributes.fetch(:workDoneProgress)
        end

        #
        # The server provides support to resolve additional
        # information for a workspace symbol.
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
