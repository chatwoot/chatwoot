module LanguageServer
  module Protocol
    module Interface
      #
      # Notebook specific client capabilities.
      #
      class NotebookDocumentSyncClientCapabilities
        def initialize(dynamic_registration: nil, execution_summary_support: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:executionSummarySupport] = execution_summary_support if execution_summary_support

          @attributes.freeze
        end

        #
        # Whether implementation supports dynamic registration. If this is
        # set to `true` the client supports the new
        # `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
        # return value for the corresponding server capability as well.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # The client supports sending execution summary data per cell.
        #
        # @return [boolean]
        def execution_summary_support
          attributes.fetch(:executionSummarySupport)
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
