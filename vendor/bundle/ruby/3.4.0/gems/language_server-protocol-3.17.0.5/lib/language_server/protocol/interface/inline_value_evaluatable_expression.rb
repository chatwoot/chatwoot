module LanguageServer
  module Protocol
    module Interface
      #
      # Provide an inline value through an expression evaluation.
      #
      # If only a range is specified, the expression will be extracted from the
      # underlying document.
      #
      # An optional expression can be used to override the extracted expression.
      #
      class InlineValueEvaluatableExpression
        def initialize(range:, expression: nil)
          @attributes = {}

          @attributes[:range] = range
          @attributes[:expression] = expression if expression

          @attributes.freeze
        end

        #
        # The document range for which the inline value applies.
        # The range is used to extract the evaluatable expression from the
        # underlying document.
        #
        # @return [Range]
        def range
          attributes.fetch(:range)
        end

        #
        # If specified the expression overrides the extracted expression.
        #
        # @return [string]
        def expression
          attributes.fetch(:expression)
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
