module LanguageServer
  module Protocol
    module Interface
      class InlineValueContext
        def initialize(frame_id:, stopped_location:)
          @attributes = {}

          @attributes[:frameId] = frame_id
          @attributes[:stoppedLocation] = stopped_location

          @attributes.freeze
        end

        #
        # The stack frame (as a DAP Id) where the execution has stopped.
        #
        # @return [number]
        def frame_id
          attributes.fetch(:frameId)
        end

        #
        # The document range where execution has stopped.
        # Typically the end position of the range denotes the line where the
        # inline values are shown.
        #
        # @return [Range]
        def stopped_location
          attributes.fetch(:stoppedLocation)
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
