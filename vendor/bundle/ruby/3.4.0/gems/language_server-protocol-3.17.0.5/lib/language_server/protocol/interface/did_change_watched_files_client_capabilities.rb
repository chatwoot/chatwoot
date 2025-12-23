module LanguageServer
  module Protocol
    module Interface
      class DidChangeWatchedFilesClientCapabilities
        def initialize(dynamic_registration: nil, relative_pattern_support: nil)
          @attributes = {}

          @attributes[:dynamicRegistration] = dynamic_registration if dynamic_registration
          @attributes[:relativePatternSupport] = relative_pattern_support if relative_pattern_support

          @attributes.freeze
        end

        #
        # Did change watched files notification supports dynamic registration.
        # Please note that the current protocol doesn't support static
        # configuration for file changes from the server side.
        #
        # @return [boolean]
        def dynamic_registration
          attributes.fetch(:dynamicRegistration)
        end

        #
        # Whether the client has support for relative patterns
        # or not.
        #
        # @return [boolean]
        def relative_pattern_support
          attributes.fetch(:relativePatternSupport)
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
