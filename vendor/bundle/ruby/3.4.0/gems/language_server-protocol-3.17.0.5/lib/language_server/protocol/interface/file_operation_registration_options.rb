module LanguageServer
  module Protocol
    module Interface
      #
      # The options to register for file operations.
      #
      class FileOperationRegistrationOptions
        def initialize(filters:)
          @attributes = {}

          @attributes[:filters] = filters

          @attributes.freeze
        end

        #
        # The actual filters.
        #
        # @return [FileOperationFilter[]]
        def filters
          attributes.fetch(:filters)
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
