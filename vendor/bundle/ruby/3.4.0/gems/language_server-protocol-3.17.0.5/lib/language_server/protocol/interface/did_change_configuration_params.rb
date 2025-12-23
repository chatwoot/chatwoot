module LanguageServer
  module Protocol
    module Interface
      class DidChangeConfigurationParams
        def initialize(settings:)
          @attributes = {}

          @attributes[:settings] = settings

          @attributes.freeze
        end

        #
        # The actual changed settings
        #
        # @return [LSPAny]
        def settings
          attributes.fetch(:settings)
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
