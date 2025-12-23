module LanguageServer
  module Protocol
    module Interface
      class SemanticTokens
        def initialize(result_id: nil, data:)
          @attributes = {}

          @attributes[:resultId] = result_id if result_id
          @attributes[:data] = data

          @attributes.freeze
        end

        #
        # An optional result id. If provided and clients support delta updating
        # the client will include the result id in the next semantic token request.
        # A server can then instead of computing all semantic tokens again simply
        # send a delta.
        #
        # @return [string]
        def result_id
          attributes.fetch(:resultId)
        end

        #
        # The actual tokens.
        #
        # @return [number[]]
        def data
          attributes.fetch(:data)
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
