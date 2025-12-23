module LanguageServer
  module Protocol
    module Interface
      #
      # An event describing a file change.
      #
      class FileEvent
        def initialize(uri:, type:)
          @attributes = {}

          @attributes[:uri] = uri
          @attributes[:type] = type

          @attributes.freeze
        end

        #
        # The file's URI.
        #
        # @return [string]
        def uri
          attributes.fetch(:uri)
        end

        #
        # The change type.
        #
        # @return [number]
        def type
          attributes.fetch(:type)
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
