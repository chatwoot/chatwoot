module LanguageServer
  module Protocol
    module Interface
      #
      # Provide inline value as text.
      #
      class InlineValueText
        def initialize(range:, text:)
          @attributes = {}

          @attributes[:range] = range
          @attributes[:text] = text

          @attributes.freeze
        end

        #
        # The document range for which the inline value applies.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
        end

        #
        # The text of the inline value.
        #
        # @return [string]
        def text
          attributes.fetch(:text)
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
