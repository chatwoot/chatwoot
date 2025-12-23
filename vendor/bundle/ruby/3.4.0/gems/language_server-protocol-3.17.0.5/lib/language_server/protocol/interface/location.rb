module LanguageServer
  module Protocol
    module Interface
      class Location
        def initialize(uri:, range:)
          @attributes = {}

          @attributes[:uri] = uri
          @attributes[:range] = range

          @attributes.freeze
        end

        # @return [string]
        def uri
          attributes.fetch(:uri)
        end

        # @return [Range]
        def range
          attributes.fetch(:range)
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
