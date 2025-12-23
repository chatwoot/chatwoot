module LanguageServer
  module Protocol
    module Interface
      class DocumentLinkRegistrationOptions
        def initialize(document_selector:, work_done_progress: nil, resolve_provider: nil)
          @attributes = {}

          @attributes[:documentSelector] = document_selector
          @attributes[:workDoneProgress] = work_done_progress if work_done_progress
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
        # Document links have a resolve provider as well.
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
