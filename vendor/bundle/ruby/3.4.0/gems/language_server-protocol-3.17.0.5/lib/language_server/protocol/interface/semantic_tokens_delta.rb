module LanguageServer
  module Protocol
    module Interface
      class SemanticTokensDelta
        def initialize(result_id: nil, edits:)
          @attributes = {}

          @attributes[:resultId] = result_id if result_id
          @attributes[:edits] = edits

          @attributes.freeze
        end

        # @return [string]
        def result_id
          attributes.fetch(:resultId)
        end

        #
        # The semantic token edits to transform a previous result into a new
        # result.
        #
        # @return [SemanticTokensEdit[]]
        def edits
          attributes.fetch(:edits)
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
