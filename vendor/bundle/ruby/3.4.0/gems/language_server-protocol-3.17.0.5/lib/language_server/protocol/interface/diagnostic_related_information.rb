module LanguageServer
  module Protocol
    module Interface
      #
      # Represents a related message and source code location for a diagnostic.
      # This should be used to point to code locations that cause or are related to
      # a diagnostics, e.g when duplicating a symbol in a scope.
      #
      class DiagnosticRelatedInformation
        def initialize(location:, message:)
          @attributes = {}

          @attributes[:location] = location
          @attributes[:message] = message

          @attributes.freeze
        end

        #
        # The location of this related diagnostic information.
        #
        # @return [Location]
        def location
          attributes.fetch(:location)
        end

        #
        # The message of this related diagnostic information.
        #
        # @return [string]
        def message
          attributes.fetch(:message)
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
