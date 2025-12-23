module LanguageServer
  module Protocol
    module Interface
      class Position
        def initialize(line:, character:)
          @attributes = {}

          @attributes[:line] = line
          @attributes[:character] = character

          @attributes.freeze
        end

        #
        # Line position in a document (zero-based).
        #
        # @return [number]
        def line
          attributes.fetch(:line)
        end

        #
        # Character offset on a line in a document (zero-based). The meaning of this
        # offset is determined by the negotiated `PositionEncodingKind`.
        #
        # If the character value is greater than the line length it defaults back
        # to the line length.
        #
        # @return [number]
        def character
          attributes.fetch(:character)
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
