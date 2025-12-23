module LanguageServer
  module Protocol
    module Interface
      #
      # The result of a hover request.
      #
      class Hover
        def initialize(contents:, range: nil)
          @attributes = {}

          @attributes[:contents] = contents
          @attributes[:range] = range if range

          @attributes.freeze
        end

        #
        # The hover's content
        #
        # @return [MarkupContent | MarkedString | MarkedString[]]
        def contents
          attributes.fetch(:contents)
        end

        #
        # An optional range is a range inside a text document
        # that is used to visualize a hover, e.g. by changing the background color.
        #
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
