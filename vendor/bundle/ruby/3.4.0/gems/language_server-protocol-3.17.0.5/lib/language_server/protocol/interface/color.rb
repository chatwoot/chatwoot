module LanguageServer
  module Protocol
    module Interface
      #
      # Represents a color in RGBA space.
      #
      class Color
        def initialize(red:, green:, blue:, alpha:)
          @attributes = {}

          @attributes[:red] = red
          @attributes[:green] = green
          @attributes[:blue] = blue
          @attributes[:alpha] = alpha

          @attributes.freeze
        end

        #
        # The red component of this color in the range [0-1].
        #
        # @return [number]
        def red
          attributes.fetch(:red)
        end

        #
        # The green component of this color in the range [0-1].
        #
        # @return [number]
        def green
          attributes.fetch(:green)
        end

        #
        # The blue component of this color in the range [0-1].
        #
        # @return [number]
        def blue
          attributes.fetch(:blue)
        end

        #
        # The alpha component of this color in the range [0-1].
        #
        # @return [number]
        def alpha
          attributes.fetch(:alpha)
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
