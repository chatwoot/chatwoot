module LanguageServer
  module Protocol
    module Interface
      class ColorInformation
        def initialize(range:, color:)
          @attributes = {}

          @attributes[:range] = range
          @attributes[:color] = color

          @attributes.freeze
        end

        #
        # The range in the document where this color appears.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
        end

        #
        # The actual color value for this color range.
        #
        # @return [Color]
        def color
          attributes.fetch(:color)
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
