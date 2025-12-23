module LanguageServer
  module Protocol
    module Interface
      class DocumentSymbolRegistrationOptions
        def initialize(document_selector:, work_done_progress: nil, label: nil)
          @attributes = {}

          @attributes[:documentSelector] = document_selector
          @attributes[:workDoneProgress] = work_done_progress if work_done_progress
          @attributes[:label] = label if label

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
        # A human-readable string that is shown when multiple outlines trees
        # are shown for the same document.
        #
        # @return [string]
        def label
          attributes.fetch(:label)
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
