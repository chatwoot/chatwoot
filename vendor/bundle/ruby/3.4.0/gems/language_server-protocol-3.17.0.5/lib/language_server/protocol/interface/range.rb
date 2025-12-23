module LanguageServer
  module Protocol
    module Interface
      class Range
        def initialize(start:, end:)
          @attributes = {}

          @attributes[:start] = start
          @attributes[:end] = binding.local_variable_get(:end)

          @attributes.freeze
        end

        #
        # The range's start position.
        #
        # @return [Position]
        def start
          attributes.fetch(:start)
        end

        #
        # The range's end position.
        #
        # @return [Position]
        def end
          attributes.fetch(:end)
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
