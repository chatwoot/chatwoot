module LanguageServer
  module Protocol
    module Interface
      class SemanticTokensEdit
        def initialize(start:, delete_count:, data: nil)
          @attributes = {}

          @attributes[:start] = start
          @attributes[:deleteCount] = delete_count
          @attributes[:data] = data if data

          @attributes.freeze
        end

        #
        # The start offset of the edit.
        #
        # @return [number]
        def start
          attributes.fetch(:start)
        end

        #
        # The count of elements to remove.
        #
        # @return [number]
        def delete_count
          attributes.fetch(:deleteCount)
        end

        #
        # The elements to insert.
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
