module LanguageServer
  module Protocol
    module Interface
      #
      # Capabilities specific to the notebook document support.
      #
      class NotebookDocumentClientCapabilities
        def initialize(synchronization:)
          @attributes = {}

          @attributes[:synchronization] = synchronization

          @attributes.freeze
        end

        #
        # Capabilities specific to notebook document synchronization
        #
        # @return [NotebookDocumentSyncClientCapabilities]
        def synchronization
          attributes.fetch(:synchronization)
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
